function normalizeApiBaseUrl(value) {
  try {
    var parsed = new URL(String(value).trim());
    if (
      parsed.protocol !== "https:" ||
      parsed.username ||
      parsed.password ||
      parsed.search ||
      parsed.hash
    ) {
      return null;
    }
    return parsed.href.replace(/\/+$/, "");
  } catch (error) {
    return null;
  }
}

async function saveClientConfiguration(storage, apiBaseUrl, apiKey) {
  var normalizedBaseUrl = normalizeApiBaseUrl(apiBaseUrl);
  var normalizedApiKey = String(apiKey || "").trim();
  if (!normalizedBaseUrl) {
    throw new Error("Enter a valid HTTPS API URL.");
  }
  if (!normalizedApiKey) {
    throw new Error("Enter an API key for this browser session.");
  }

  await storage.local.set({ gptDocsApiBaseUrl: normalizedBaseUrl });
  await storage.session.set({ gptDocsApiKey: normalizedApiKey });
}

// Wire options page
var settingsForm = document.getElementById("settingsForm");
var apiBaseUrlInput = document.getElementById("apiBaseUrl");
var apiKeyInput = document.getElementById("apiKey");
var statusElement = document.getElementById("status");

chrome.storage.local.get(["gptDocsApiBaseUrl"], function (values) {
  apiBaseUrlInput.value = values.gptDocsApiBaseUrl || "";
});

settingsForm.addEventListener("submit", function (event) {
  event.preventDefault();
  statusElement.textContent = "";
  saveClientConfiguration(
    chrome.storage,
    apiBaseUrlInput.value,
    apiKeyInput.value,
  ).then(function () {
    apiKeyInput.value = "";
    statusElement.textContent = "Settings saved for this browser session.";
  }).catch(function (error) {
    statusElement.textContent = error.message;
  });
});
