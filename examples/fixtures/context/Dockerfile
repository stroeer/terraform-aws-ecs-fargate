FROM python:3.9-alpine

ADD index.html index.html
ADD server.py server.py

USER app
EXPOSE 8000

ENTRYPOINT ["python3", "server.py"]
