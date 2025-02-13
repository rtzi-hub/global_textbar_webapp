resource "aws_instance" "web_server" {
  ami                    = "ami-085ad6ae776d8f09c"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "Ron1"

  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -ex  # Stop script on error and show commands

    LOGFILE="/var/log/user-data.log"
    exec > >(tee -a $LOGFILE) 2>&1

    echo "=== Updating system packages ==="
    dnf update -y || echo "Warning: dnf update failed"

    echo "=== Installing required dependencies ==="
    dnf install -y python3 python3-pip python3-devel nginx systemd unzip git || echo "Warning: package install failed"

    echo "=== Setting up Python virtual environment ==="
    mkdir -p /home/ec2-user/app
    cd /home/ec2-user/app
    python3 -m venv venv || echo "Warning: venv creation failed"
    source venv/bin/activate
    python3 -m ensurepip --default-pip
    pip install --upgrade pip
    pip install flask boto3 gunicorn
    echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ip-forward.conf
    sudo sysctl --system

    echo "=== Creating Flask application ==="
    cat <<EOT > /home/ec2-user/app/app.py
    from flask import Flask, request, jsonify, render_template
    import boto3

    app = Flask(__name__, static_folder="static", template_folder=".")

    s3 = boto3.client('s3')
    BUCKET_NAME = "words-submission-bucket"

    @app.route("/")
    def home():
        return render_template("index.html")

    @app.route("/submit", methods=["POST"])
    def submit():
        try:
            word = request.json.get("word")
            if word:
                s3.put_object(Bucket=BUCKET_NAME, Key=f"{word}.txt", Body=word)
                return jsonify({"message": "Word saved!"})
            return jsonify({"error": "No word provided"}), 400
        except Exception as e:
            print("Error in /submit:", str(e))
            return jsonify({"error": "Server error"}), 500

    @app.route("/words", methods=["GET"])
    def get_words():
        try:
            objects = s3.list_objects_v2(Bucket=BUCKET_NAME)
            words = [obj["Key"].replace(".txt", "") for obj in objects.get("Contents", [])]
            return jsonify({"words": words})
        except Exception as e:
            print("Error in /words:", str(e))
            return jsonify({"error": "Server error"}), 500

    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=5000)
    EOT

    echo "=== Creating Frontend HTML ==="
    cat <<EOT > /home/ec2-user/app/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Word Submission - Global List</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #1e3c72, #2a5298);
            color: #fff;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            padding: 20px;
            text-align: center;
        }

        h1 {
            font-size: 2.5rem;
            font-weight: 600;
            margin-bottom: 10px;
        }

        p {
            font-size: 1.2rem;
            opacity: 0.8;
            margin-bottom: 20px;
        }

        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
            width: 100%;
            max-width: 400px;
            backdrop-filter: blur(10px);
        }

        input {
            width: 100%;
            padding: 12px;
            border: none;
            border-radius: 6px;
            font-size: 1rem;
            margin-bottom: 10px;
            outline: none;
            text-align: center;
        }

        button {
            width: 100%;
            background: #ff8c00;
            color: white;
            border: none;
            padding: 12px;
            border-radius: 6px;
            font-size: 1.1rem;
            font-weight: bold;
            cursor: pointer;
            transition: 0.3s;
        }

        button:hover {
            background: #ffa726;
        }

        .word-list {
            margin-top: 20px;
            text-align: left;
            max-height: 200px;
            overflow-y: auto;
        }

        .word-item {
            background: rgba(255, 255, 255, 0.15);
            padding: 10px;
            margin: 5px 0;
            border-radius: 6px;
            font-size: 1rem;
            text-align: center;
        }

        .notification {
            display: none;
            padding: 10px;
            margin-top: 10px;
            border-radius: 6px;
            font-size: 1rem;
            font-weight: bold;
            text-align: center;
        }

        .success {
            background: #4caf50;
            color: white;
        }

        .error {
            background: #ff4d4d;
            color: white;
        }

        @media (max-width: 500px) {
            h1 {
                font-size: 2rem;
            }
        }
    </style>
</head>
<body>
    <h1>Submit a Word 🌍</h1>
    <p>Join the global word list community.</p>

    <div class="container">
        <input type="text" id="wordInput" placeholder="Enter a word..." />
        <button onclick="submitWord()">Submit</button>
        <div class="notification" id="notification"></div>
    </div>

    <h2>Submitted Words</h2>
    <div class="word-list" id="wordsContainer"></div>

    <script>
        async function submitWord() {
            let word = document.getElementById("wordInput").value.trim();
            let notification = document.getElementById("notification");

            if (word === "") {
                showNotification("Please enter a valid word.", "error");
                return;
            }

            await fetch("/submit", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ word: word })
            });

            document.getElementById("wordInput").value = '';
            showNotification("Word submitted successfully!", "success");
            loadWords();
        }

        async function loadWords() {
            let response = await fetch("/words");
            let data = await response.json();
            let wordsContainer = document.getElementById("wordsContainer");
            wordsContainer.innerHTML = "";

            data.words.forEach(word => {
                let wordElement = document.createElement("div");
                wordElement.className = "word-item";
                wordElement.innerText = word;
                wordsContainer.appendChild(wordElement);
            });
        }

        function showNotification(message, type) {
            const notification = document.getElementById("notification");
            notification.innerText = message;
            notification.className = `notification ${type}`;
            notification.style.display = "block";

            setTimeout(() => {
                notification.style.display = "none";
            }, 3000);
        }

        window.onload = loadWords;
    </script>
</body>
</html>

    EOT

    # Set minimal permissions while ensuring functionality
    chown ec2-user:ec2-user /home/ec2-user/app/index.html
    chmod 644 /home/ec2-user/app/index.html

    echo "=== Creating Flask systemd service ==="
    cat <<EOT > /etc/systemd/system/flask-app.service
    [Unit]
    Description=Flask Web Application
    After=network.target

    [Service]
    User=ec2-user
    WorkingDirectory=/home/ec2-user/app
    Environment="PATH=/home/ec2-user/app/venv/bin"
    ExecStart=/home/ec2-user/app/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
    Restart=always

    [Install]
    WantedBy=multi-user.target
    EOT

    echo "=== Reloading systemd and starting Flask ==="
    systemctl daemon-reload
    systemctl enable flask-app
    systemctl start flask-app || echo "Warning: Flask service failed to start"

    echo "=== Configuring Nginx as a reverse proxy ==="
    cat <<EOT > /etc/nginx/conf.d/flask-app.conf
    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://127.0.0.1:5000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    EOT

    echo "=== Restarting Nginx ==="
    systemctl enable nginx
    systemctl restart nginx || echo "Warning: Nginx failed to start"

    echo "=== User Data Script Execution Completed ==="
  EOF

  tags = {
    Name = "WebServer"
  }
}
