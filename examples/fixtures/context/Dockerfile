FROM python:3.14-alpine

RUN addgroup -S app && adduser -S app -G app
WORKDIR /home/app

ADD index.html /home/app/index.html
ADD server.py /home/app/server.py

RUN chown -R app:app /home/app

USER app

EXPOSE 8000

ENTRYPOINT ["python3", "server.py"]
