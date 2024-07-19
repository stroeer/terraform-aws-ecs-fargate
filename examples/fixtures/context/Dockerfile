FROM python:3.12-alpine

ADD index.html index.html
ADD server.py server.py

#USER app
EXPOSE 8000

ENTRYPOINT ["python3", "server.py"]
