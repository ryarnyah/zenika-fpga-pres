const fs = require("fs");
const path = require("path");
const spawn = require("child_process").spawn;

function pdfSlides() {
    return new Promise((resolve, reject) => {
        const child = spawn("node", [
            require.resolve("decktape"),
            "reveal",
            "-p",
            "0",
            "--size",
            "1280x1280",
            "http://localhost:8000/index.html",
            "./Zenika-slides-Slides.pdf",
        ]);

        child.stdout.on("data", function (data) {
            process.stdout.write(data);
        });

        child.stderr.on("data", function (data) {
            process.stderr.write(data);
        });

        child.on("exit", function (code) {
            if (code !== 0) {
                return reject(
                    new Error(`spawned process exited with non-zero code '${code}'`)
                );
            }
            console.log("PDF slides generated");
            resolve();
        });

        child.on("error", function (err) {
            console.error("PDF slides generation failed!", err);
            reject(err);
        });
    });
}

if (require.main === module) {
    pdfSlides();
}
