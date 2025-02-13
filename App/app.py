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
