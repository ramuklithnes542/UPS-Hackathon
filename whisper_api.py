from flask import Flask, request, jsonify
import whisper
import os
import subprocess
import uuid

app = Flask(__name__)
model = whisper.load_model("base")  # or "tiny", "small", etc.

def convert_to_pcm_wav(input_file, output_file):
    subprocess.run([
        "ffmpeg", "-y",
        "-i", input_file,
        "-ac", "1",        # mono
        "-ar", "16000",    # 16kHz
        output_file
    ], check=True)

@app.route("/transcribe", methods=["POST"])
def transcribe():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files['file']
    # Generate a unique base name
    unique_id = str(uuid.uuid4())
    input_ext = os.path.splitext(file.filename)[1]  # e.g., '.aac'
    input_path = f"./temp_input_{unique_id}{input_ext}"
    output_path = f"./temp_output_{unique_id}.wav"

    try:
        file.save(input_path)
        convert_to_pcm_wav(input_path, output_path)
        result = model.transcribe(output_path)
        return jsonify({"text": result["text"]})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        for f in [input_path, output_path]:
            if os.path.exists(f):
                os.remove(f)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
