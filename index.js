const dasha = require("@dasha.ai/sdk");
const fs = require("fs");

async function main() {
  const app = await dasha.deploy("./app");

  // external function check policy number. Here we are providing a random evaluation, you will want to refer to your membership database
  app.setExternal("check_policy", (args, conv) => {
    const policyNumber = args;
    console.log(policyNumber);
  });

  // external function convert policy number.
  app.setExternal("convert_policy", (args, conv) => {
    var policyRead = args.policy_number.split("").join(". ");
    console.log(policyRead);
    return policyRead;
  });

  // external function pre-existing conditions. Here we are providing a random response, you will want to refer to your membership database
  app.setExternal("pre_existing", (args, conv) => {
    const foo = Math.random();
    console.log(foo);
  });

  // external function console.log
  app.setExternal("console_log", (args, conv) => {
    console.log(args);
  });

  // external split name
  app.setExternal("split_name", (args, conv) => {
    var input = args.name;
    var fields = input.split(' ');
    var name = fields[0];
    console.log(name);
    return name;
  });



  await app.start();

  const conv = app.createConversation({
    phone: process.argv[2] ?? "",
    name: process.argv[3] ?? "",
  });

  conv.audio.tts = "dasha";

  if (conv.input.phone === "chat") {
    await dasha.chat.createConsoleChat(conv);
  } else {
    conv.on("transcription", console.log);
  }

  const logFile = await fs.promises.open("./log.txt", "w");
  await logFile.appendFile("#".repeat(100) + "\n");

  conv.on("transcription", async (entry) => {
    await logFile.appendFile(`${entry.speaker}: ${entry.text}\n`);
  });

  conv.on("debugLog", async (event) => {
    if (event?.msg?.msgId === "RecognizedSpeechMessage") {
      const logEntry = event?.msg?.results[0]?.facts;
      await logFile.appendFile(JSON.stringify(logEntry, undefined, 2) + "\n");
    }
  });

  const result = await conv.execute({
    channel: conv.input.phone === "chat" ? "text" : "audio",
  });

  console.log(result.output);

  await app.stop();
  app.dispose();

  await logFile.close();
}

main().catch(() => {});
