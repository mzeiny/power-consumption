FROM python:3

RUN apt update && apt install -y powertop

ADD requirements.txt /
RUN pip install -r requirements.txt

ADD main.py /


CMD [ "python", "-u", "/main.py" ]
