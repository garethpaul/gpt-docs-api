//
// Define the CSS rules to be injected
// use the twilio-sans font
// set the background color of the nav bar to #7C61F5
var cssRules = `

`;

var inputText = "Ask a question...";
var currentIndex = 0;
function clearInput() {
  document.getElementById("queryInput").value = "";
}

// Create a new <style> element
var styleElement = document.createElement("style");
styleElement.type = "text/css";
styleElement.innerHTML = cssRules;

// Append the <style> element to the <head> element of the page
document.head.appendChild(styleElement);

// Create a new list item element
var newListItem = document.createElement("li");

// Set the class for the new list item
newListItem.className = "docs-nav__item";

// Get the logo-nav.svg image
var newLogoNavImg;
if (chrome.runtime) {
  newLogoNavImg = chrome.runtime.getURL("gpt-docs-nav.png");
} else {
  newLogoNavImg = "gpt-docs-nav.png";
}
//const newLogoNavImg = chrome.runtime.getURL("logo-nav.svg");

function darkenDom(b) {
  // assume that b is a boolean value that tells you whether to add or remove the overlay
  if (b) {
    // Create a new <div> element to serve as the overlay
    var overlay = document.createElement("div");
    // set the className
    overlay.className = "overlay-darken";
    // Append the overlay to the <body> element of the page
    document.body.appendChild(overlay);
  } else {
    // remove the overlay
    document.querySelector(".overlay-darken").remove();
  }
}

function addResponse(text, links, parentElement) {
  // under the content add a div to hold an element with the className .modal-response
  var response = document.createElement("div");
  response.className = "modal-response";
  // add a h2 element to the response div element
  var h2 = document.createElement("h2");
  h2.className = "modal-response-h2";
  // set the inner text of the h2 element as the input text from #queryInput but capitalized
  var inputText = document.getElementById("queryInput").value;
  var inputText = inputText.charAt(0).toUpperCase() + inputText.slice(1);
  // add a question mark to the end of the input text if it doesn't already have one
  if (inputText.charAt(inputText.length - 1) !== "?") {
    inputText = inputText + "?";
  }

  h2.innerHTML = inputText;

  response.appendChild(h2);
  // add a p element to the response div element
  var p = document.createElement("p");
  p.className = "response__p";
  p.innerHTML = text;
  response.appendChild(p);

  // Create another h2 element that says "Sources"
  var h2 = document.createElement("h2");
  h2.className = "modal-response-h2";
  h2.innerHTML = "Sources";
  response.appendChild(h2);

  // create a list of a links with the className .modal-response__link
  var ul = document.createElement("ul");
  ul.className = "modal-response__link";

  // loop through the links array
  for (var i = 0; i < links.length; i++) {
    // create a new list item element
    var newListItem = document.createElement("li");
    // set the className
    newListItem.className = "modal-response__link";
    // create a new anchor element
    var newAnchor = document.createElement("a");
    // set the className
    newAnchor.className = "modal-response__link";
    // set the href attribute
    newAnchor.setAttribute("href", links[i]);
    // set the target attribute
    newAnchor.setAttribute("target", "_blank");
    // set the innerHTML
    newAnchor.innerHTML = links[i];

    // append the anchor element to the list item element
    newListItem.appendChild(newAnchor);
    // append the list item element to the list element
    ul.appendChild(newListItem);

    // append the list element to the response div element
    response.appendChild(ul);
  }

  // add a h3 element to the response div element
  var h3 = document.createElement("h3");
  h3.className = "modal-response__h3";
  h3.innerHTML = "Was this response useful?";
  response.appendChild(h3);

  // create div with class modal-response__button_container
  var buttonContainer = document.createElement("div");
  buttonContainer.className = "modal-response__button_container";
  // create a yes and no button for the user to click with the question was this response useful
  var yesButton = document.createElement("button");
  yesButton.className = "modal-response__button";
  yesButton.innerHTML = "Yes";
  buttonContainer.appendChild(yesButton);

  var noButton = document.createElement("button");
  noButton.className = "modal-response__button";
  noButton.innerHTML = "No";
  buttonContainer.appendChild(noButton);

  // add click event listeners to the yes and no buttons
  yesButton.addEventListener("click", function () {
    // add a class of .modal-response__button--clicked to the yes button
    // remove the buttons and add a thank you message
    // create p class for thank you message
    var thankyou = document.createElement("p");
    thankyou.className = "modal-response__p";
    thankyou.innerHTML = "Thank you for your feedback!";
    // append the thank you message to the response div element
    response.appendChild(thankyou);
    // remove the yes and no buttons
    yesButton.remove();
    noButton.remove();
  });

  response.appendChild(buttonContainer);

  // add a h2 element to the response div element
  parentElement.appendChild(response);
}

function removeLoader(parentElement) {
  // remove the loader
  parentElement.querySelector(".gpt-loading").remove();
}

function createLoader(parentElement) {
  // create a new <div> element to serve as the loader
  var wrap = document.createElement("div");
  wrap.className = "gpt-loading";

  // Create an h2 element that says "Gathering sources ..."
  var h2 = document.createElement("h2");
  h2.className = "gpt-loading__h2";
  h2.innerHTML = "Gathering sources ...";

  // Define the array of messages to rotate
  const messages = [
    "Gathering sources ...",
    "Scouring the earth ...",
    "Calling a friend ...",
    "Asking my boss ...",
  ];

  // Initialize the counter
  let counter = 0;

  // Rotate the innerHTML of the h2 element every 5 seconds
  setInterval(function () {
    // Set the innerHTML to the current message
    h2.innerHTML = messages[counter];

    // Increment the counter
    counter++;

    // Reset the counter if it exceeds the length of the messages array
    if (counter >= messages.length) {
      counter = 0;
    }
  }, 2500); // Update interval to 5000ms (5 seconds)
  wrap.appendChild(h2);

  // Create the loading bar
  var loadingBarContainer = document.createElement("div");
  loadingBarContainer.className = "loading-bar-container";

  var loadingBar = document.createElement("div");
  loadingBar.className = "loading-bar";
  loadingBarContainer.appendChild(loadingBar);
  wrap.appendChild(loadingBarContainer);

  // Append the loader to the parent element
  parentElement.appendChild(wrap);
}

function addModal(b) {
  if (b) {
    // Create a new <div> element to serve as the modal
    var modal = document.createElement("div");
    // set the className
    modal.className = "modal";
    // Append the modal to the <body> element of the page
    modal.classList.add("modal-show");

    // Add a top bar to the modal
    var topBar = document.createElement("div");
    topBar.className = "top-bar";
    // add a close button to the right of the bar
    var close = document.createElement("span");
    close.className = "close";
    close.innerHTML = "&times;";
    // when the user clicks on the close button, remove the overlay

    // Add a title to the top bar
    var title = document.createElement("h2");
    title.className = "top-bar__title";
    title.innerHTML = "GPT Docs";
    topBar.appendChild(title);
    // add a pill to the right of the title with experimental with a background of #f22f46 and and a color of a lighter version of that red
    // create a div element to hold the pill
    var pillContainer = document.createElement("div");
    pillContainer.className = "pill-container";

    var pill = document.createElement("span");
    pill.className = "pill";
    pill.innerHTML = "Experimental";
    // add wave-text class to the pill
    pill.classList.add("wave-text");

    pillContainer.appendChild(pill);
    topBar.appendChild(pillContainer);

    topBar.appendChild(close);
    modal.appendChild(topBar);

    // add a div element under the top bar to hold the content
    var content = document.createElement("div");
    content.className = "modal-content";

    // add two div elements to the content div element one on the left and one on the right
    var left = document.createElement("div");
    left.className = "left";

    var right = document.createElement("div");
    right.className = "right";

    // add a div element to the left div element
    var leftContent = document.createElement("div");
    leftContent.className = "left-content";

    var question = document.createElement("img");
    question.className = "question";
    if (chrome.runtime) {
      question.src = chrome.runtime.getURL("question.svg");
    } else {
      question.src = "question.svg";
    }
    //question.src = chrome.runtime.getURL("question.svg");

    // Append the content to the left
    leftContent.appendChild(question);
    left.appendChild(leftContent);

    // add a div element to the right div element
    var rightContent = document.createElement("div");
    rightContent.className = "right-content";

    // add a query form to the right content div with "Ask a question.. " as the placeholder remove all the border and background stuff
    var form = document.createElement("form");
    form.className = "form";

    // add a input element to the form element
    var input = document.createElement("input");
    input.className = "input";
    input.id = "queryInput";
    input.autocomplete = "off";
    input.placeholder = "Ask a question..";
    // have a keyboard event listener on the input element
    // when the user presses enter log the output from the input element
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      // log the output from the input element
      console.log(input.value);

      // remove existing response .modal-response
      var existingResponse = document.querySelector(".modal-response");
      if (existingResponse) {
        existingResponse.remove();
      }
      // Make an api request to http://localhost:3000/ask
      // with the input value as the query
      // and the response data as the response
      // and the modal as the modal
      createLoader(modal);
      fetch("https://gpt-docs.api.garethpaul.com/ask", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          query: input.value,
        }),
      }).then((response) => {
        response.json().then((data) => {
          // remove the loader
          removeLoader(modal);
          // if there is an existing response remove it
          addResponse(data.response, data.links, modal);
          // clear the input value
          clearInput();
        });
      });
    });

    // add a type writer effect to the end of the input text e.g. so that the "Ask a question.." text is typed out and then the cursor blinks
    // add the input to the form

    form.appendChild(input);
    var typewriterText = document.createElement("span");
    typewriterText.id = "typewriterText";
    typewriterText.innerHTML = "";
    //form.appendChild(typewriterText);
    var cursor = document.createElement("span");
    cursor.className = "cursor";
    cursor.innerHTML = "▌";
    //form.appendChild(cursor);

    // add the form to the right content div element
    rightContent.appendChild(form);
    // add right content to the right div element
    right.appendChild(rightContent);

    // add both div elements to the content div element
    content.appendChild(left);
    content.appendChild(right);
    modal.appendChild(content);

    close.addEventListener("click", function () {
      // remove the overlay div element

      document.querySelector(".overlay-darken").remove();
      // remove the modal div element
      document.querySelector(".modal").remove();
    });
    document.body.appendChild(modal);
  }
}

// create a function to add an overlay modal to the page when the the user clicks on docs-nav__link
function addOverlay() {
  //
  analytics.track("Modal Opened", {
    modalName: "Example Modal", // Custom property: name of the modal
    timestamp: new Date(), // Custom property: timestamp when the modal was opened
  });
  // darken the page
  darkenDom(true);
  // create a new div element
  addModal(true);
  // get the close element
  var close = document.getElementsByClassName("close")[0];
  // add an event listener to the close element
  close.addEventListener("click", function () {
    // remove the overlay div element
    // remove the overlay div element
    darkenDom(false);
    document.querySelector(".overlay").remove();
    // remove the modal div element
    document.querySelector(".modal").remove();
  });

  // add the cursor to the input element
  document.querySelector("#queryInput").focus();
  document.querySelector("#queryInput").focus();

  // show the overlay div element above the page content
  // if the overlay query selector returns null then create a new div element
  if (document.querySelector(".overlay")) {
    document.querySelector(".overlay").style.display = "block";
  }

  // add an event listener to the window
  window.addEventListener("click", function (event) {
    // check if the target of the event is the overlay div element
    if (event.target == document.querySelector(".overlay")) {
      // remove the overlay div element
      document.querySelector(".overlay").remove();
    }
  });
}

// add a keybinding for command and g on a mac to addOverlay
document.addEventListener("keydown", function (event) {
  // Check if the Command key (event.metaKey) is pressed and if the key is "m"
  if (event.metaKey && event.key.toLowerCase() === "i") {
    // Call the addOverlay function
    addOverlay();
  }
});

// add an event listener to the new list item
newListItem.addEventListener("click", addOverlay);

// Set the inner HTML for the new list item (replace with your desired content)
newListItem.innerHTML =
  '<a class="docs-nav__link gpt-docs-nav-link">' +
  '<img src="' +
  newLogoNavImg +
  '" alt="Your Alt Text" class="docs-nav__icon">' +
  '<span class="docs-nav__text"></span>' +
  "</a>";

// Get the unordered list element with the class 'docs-nav__secondary'
var ulElement = document.querySelector(".docs-nav__secondary");

// Check if the unordered list element exists
if (ulElement) {
  // Insert the new list item at the beginning of the unordered list
  // insert at the end
  // insert at the end

  //ulElement.appendChild(newListItem);
  // append the newListItem to docs-nav__secondary between the 2nd and 3rd list item
  ulElement.insertBefore(newListItem, ulElement.childNodes[7]);
} else {
  console.error(
    'Unable to find the unordered list element with class "docs-nav__secondary"'
  );
}

analytics.load("LWB8p2QcYRfO9IHKrwOyfEJomenvUODG");
analytics.page();
