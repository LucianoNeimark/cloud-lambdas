# Dockerfile
FROM node:14

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

ARG REACT_APP_API_URL
ARG LOGIN_URL

ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV LOGIN_URL=$LOGIN_URL

RUN npm run build