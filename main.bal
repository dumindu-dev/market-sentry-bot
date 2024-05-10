import ballerina/http;
import ballerina/url;
import ballerina/io;
import ballerina/lang.value;
import ballerinax/mongodb;

configurable string telegramToken = ?;
configurable string mongoConnectionString = ?;

string encodedTelegramToken = check url:encode(telegramToken,"UTF-8");
string telegramBotAuth = "/bot"+encodedTelegramToken+"/";

string SEND_MESSAGE_ENDPOINT = telegramBotAuth + "sendMessage";
string SEND_STICKER_ENDPOINT = telegramBotAuth + "sendSticker";

string WELCOME_MESSAGE = "Hello and welcome to MarketSentry Bot!\nI'm thrilled to have you here! Here's what I can do to help you:\n\nDividend Alerts\nDaily performance alerts\nFilter alerts (coming soon)\n\nBefore we get started, please provide me with the authentication token you obtained from the settings page (https://market-sentry.choreoapps.dev/settings) in the web app. Simply send me the token to proceed.\n\nHappy trading!";
string WELCOME_STICKER_ID = "CAACAgIAAxkBAAM2ZhDMlW6ikH0ZHQvz6R_e2_4gYtUAAgUAA8A2TxP5al-agmtNdTQE";

string CONFUSION_MESSAGE = "I'm sorry, I'm just a simple bot designed to authenticate users and deliver alerts. I'm not equipped to understand messages beyond that scope. If you need assistance, feel free to use the /help option for guidance on how to interact with me.";
string CONFUSION_STICKER_ID = "CAACAgIAAxkBAANLZhDXYaltL3wjVwt5718RheX00DAAAhIAA8A2TxMzvJ4BLpUHNzQE";

string NO_ACCOUNT_MESSAGE = "Oops! It seems like the token you provided is invalid. Please double-check the token you entered and try again.";
string NO_ACCOUNT_STICKER_ID = "CAACAgIAAxkBAANDZhDV3HFE0KHMklNS5CB3jW74IlcAAhgAA8A2TxPW-ie_nGoY-DQE";

string HELP_MESSAGE = "To get started and receive alerts, follow these simple steps:\n1. Log in to the MarketSentry web portal.\n2. Navigate to the Settings page (https://market-sentry.choreoapps.dev/settings).\n3. Copy the authentication token provided.\n4. Paste the token here to authenticate your account with the bot.\n\nIf you ever decide you no longer need to receive alerts from this bot, simply disconnect it from the Settings page on the web portal.";
string HELP_STICKER_ID = "CAACAgIAAxkBAAPQZhEAAUSKeyCpmKVBmAl0UDeIFLQyAAIGAAPANk8Tx8qi9LJucHY0BA";

string ACCOUNT_CONNECTED_MESSAGE = "You've successfully authenticated. You're all set to receive alerts and stay updated on your views and filters.";
string ACCOUNT_CONNECTED_STICKER_ID = "CAACAgIAAxkBAANmZhDcNq3KobIEH4mAuwSQ6tNFwVsAAhUAA8A2TxPNVqY7YZ5k5zQE";


listener http:Listener httpListener = new (8290);

function updateUserChatId(int chat_id, string token)returns int|error{
    mongodb:Client mongoClient = checkpanic new ( {
        connection:mongoConnectionString
    });

    mongodb:Database stockDb = check mongoClient->getDatabase("stocks_dev");
    mongodb:Collection usersCollection = check stockDb->getCollection("users");

    map<json> replaceFilter = { "telegramToken": token };
    map<json> replaceDoc = { "telegramChatId": chat_id};

    mongodb:UpdateResult updatedCountResult = check usersCollection->updateMany(replaceFilter,{set:replaceDoc});

    int modifiedCount = updatedCountResult.modifiedCount;

    error? er = mongoClient->close();
    return modifiedCount;
}

function sendTelegramMessageWithSticker(int chat_id, string message, string sticker) returns error?{
    http:Client telegramClient = check new ("https://api.telegram.org");

    json responce = check telegramClient->post(SEND_STICKER_ENDPOINT,{
        chat_id: chat_id,
        sticker: sticker
    });
    responce = check telegramClient->post(SEND_MESSAGE_ENDPOINT,{
        chat_id: chat_id,
        text: message
    });
}

service / on httpListener {
    resource function get .(http:Request req) returns string|error {
        return "Test endpoint";
    }
    resource function post .(http:Request req) returns int|error {
        json abcd = check req.getJsonPayload();
        int chat_id = check value:ensureType(abcd.message.chat.id, int);
        string? messageRaw = check abcd.message?.text;
        string messageText = messageRaw == () ? "" :messageRaw;

        string|error|() response = "";

        if messageText.startsWith("/start") {
            response = sendTelegramMessageWithSticker(chat_id,WELCOME_MESSAGE,WELCOME_STICKER_ID);
            io:println("New user started the bot.");
        }else if messageText.startsWith("/help") {
            response = sendTelegramMessageWithSticker(chat_id,HELP_MESSAGE,HELP_STICKER_ID);
            io:println("/help message received");
        }else if messageText.startsWith("tk") {
            int updatedUsers = check updateUserChatId(chat_id, messageText);
            if updatedUsers > 0 {
                response = sendTelegramMessageWithSticker(chat_id,ACCOUNT_CONNECTED_MESSAGE,ACCOUNT_CONNECTED_STICKER_ID);
                io:println("New telegram account connected to the system");
            }else{
                response = sendTelegramMessageWithSticker(chat_id,NO_ACCOUNT_MESSAGE,NO_ACCOUNT_STICKER_ID);
                io:println("Invalid token received: "+messageText);
            }
        }else{
            response = sendTelegramMessageWithSticker(chat_id,CONFUSION_MESSAGE,CONFUSION_STICKER_ID);
            io:println("Ambiguous message received: "+messageText);
        }


        return chat_id; 
    }
}