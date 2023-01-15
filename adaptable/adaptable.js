const express = require("express");
const app = express();
const port = process.env.PORT || 3000;
var exec = require("child_process").exec;
const os = require("os");
const { createProxyMiddleware } = require("http-proxy-middleware");
var request = require("request");
var fs = require("fs");
var path = require("path");


app.get("/", (req, res) => {
  res.send("Welcome to my website...");
});


app.get("/status", (req, res) => {
  let cmdStr = "ps -ef";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>cmd exec error:\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>cmd exec results:\n" + stdout + "</pre>");
    }
  });
});


app.get("/start", (req, res) => {
  let cmdStr =
    "./adaptable/init.sh";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("cmd exec error：" + err);
    } else {
      res.send("cmd exec success");
    }
  });
});


app.use(
  "/.cachefiles/73cd83b8-bc53-4796-a631-9839b34f4b39/",
  createProxyMiddleware({
    target: "http://127.0.0.1:8081/",
    changeOrigin: true,
    ws: true,
    onProxyReq: function onProxyReq(proxyReq, req, res) {},
  })
);


app.listen(port, () => console.log(`Example app listening on port ${port}!`));
