FROM node:16

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

ENV JWT_SECRET hello
EXPOSE 81
CMD ["npm", "run", "dev"]
