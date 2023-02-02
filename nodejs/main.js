const express = require("express");
const app = express();
const port = process.env.PORT || 3000;
var exec = require("child_process").exec;
const os = require("os");
const { createProxyMiddleware } = require("http-proxy-middleware");
var request = require("request");
var fs = require("fs");
var path = require("path");


app.get("/295072cd-d094-4467-82a5-d1b9a23537ff/status", (req, res) => {
  let cmdStr = "chmod +x ./nodejs/status.sh; ./nodejs/init.sh watchdog";
  exec(cmdStr, function (err, stdout, stderr) {
    let results = "<pre>";
    if (err !== null && err !== undefined && err !== '') {
      results += "cmd exec failed\n";
      results += "\n"  + err + "\n";
    } else {
      results += "cmd exec success\n";
    }
    if (stderr !== null && stderr !== undefined && stderr !== '') {
      results += "\n" + stderr + "\n";
    }
    if (stdout !== null && stdout !== undefined && stdout !== '') {
      results += "\n" + stdout + "\n";
    }
    results += "</pre>";
    res.type("html").send(results);
  });
});


app.get("/295072cd-d094-4467-82a5-d1b9a23537ff/start", (req, res) => {
  let cmdStr =
    "chmod +x ./nodejs/init.sh; ./nodejs/init.sh";
  exec(cmdStr, function (err, stdout, stderr) {
    let results = "<pre>";
    if (err !== null && err !== undefined && err !== '') {
      results += "cmd exec failed\n";
      results += "\n"  + err + "\n";
    } else {
      results += "cmd exec success\n";
    }
    if (stderr !== null && stderr !== undefined && stderr !== '') {
      results += "\n" + stderr + "\n";
    }
    if (stdout !== null && stdout !== undefined && stdout !== '') {
      results += "\n" + stdout + "\n";
    }
    results += "</pre>";
    res.type("html").send(results);
  });
});


app.use(
  "/",
  createProxyMiddleware({
    target: "http://127.0.0.1:8080/",
    changeOrigin: true,
    ws: true,
    onProxyReq: function onProxyReq(proxyReq, req, res) {},
  })
);


app.listen(port, () => console.log(`Example app listening on port ${port}!`));
