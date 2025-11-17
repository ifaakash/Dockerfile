FROM python:3.10-slim@sha256:975a1e200a16719060d391eea4ac66ee067d709cc22a32f4ca4737731eae36c0

WORKDIR /src

COPY . ./

RUN pip install -r requirements.txt

EXPOSE 5000

CMD ["python", "main.py"]
