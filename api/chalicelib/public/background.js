chrome.runtime.onMessage.addListener(function (message, sender, sendResponse) {
  if (
    !message ||
    message.type !== "getClientConfiguration" ||
    sender.id !== chrome.runtime.id
  ) {
    return false;
  }

  chrome.storage.local.get(["gptDocsApiBaseUrl"], function (localValues) {
    if (chrome.runtime.lastError) {
      sendResponse({ apiBaseUrl: "", apiKey: "" });
      return;
    }
    chrome.storage.session.get(["gptDocsApiKey"], function (sessionValues) {
      if (chrome.runtime.lastError) {
        sendResponse({ apiBaseUrl: "", apiKey: "" });
        return;
      }
      sendResponse({
        apiBaseUrl: localValues.gptDocsApiBaseUrl || "",
        apiKey: sessionValues.gptDocsApiKey || "",
      });
    });
  });

  return true;
});
