async function closeAudibleTabs() {
    const tabs = await browser.tabs.query({});

    for (const tab of tabs) {
        if (tab.audible) {
            console.log("Closing audible tab:", tab.id, tab.url);
            await browser.tabs.remove(tab.id);
        }
    }
}

async function closeUrlTabs(urlSnippets) {
    const tabs = await browser.tabs.query({});

    for (const tab of tabs) {
        if (!tab.url) {
            continue;
        }

        if (urlSnippets.some(snippet => tab.url.includes(snippet))) {
            console.log("Closing matching tab:", tab.id, tab.url);
            await browser.tabs.remove(tab.id);
        }
    }
}

const port = browser.runtime.connectNative("panic_media");

port.onMessage.addListener(async (message) => {
    console.log("Received from native host:", message);

    if (message.command === "close_audible") {
        await closeAudibleTabs();
    }

    if (message.command === "close_urls") {
        await closeUrlTabs(message.urls);
    }
});