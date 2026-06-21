FROM python:3.12.13-alpine3.24

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir --requirement requirements.txt

CMD ["python", "app.py"]
