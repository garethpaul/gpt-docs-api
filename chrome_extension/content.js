//
// Define the CSS rules to be injected
// use the twilio-sans font
// set the background color of the nav bar to #7C61F5
var cssRules = `
@import url('https://fonts.googleapis.com/css?family=Open+Sans');

.opensans {
  font-family: "Open Sans", sans-serif;
}

.gpt-docs-nav-link {
    background-color: #7C61F5;
}
.docs-nav__icon {
    max-width: 120px;
    padding-top: 8px;
}
    .modal {
        font-family: "Open Sans", sans-serif;
      display: none;
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      padding: 20px;
      background-color: white;
      border-radius: 5px;
      animation: fadeIn 0.5s ease-in-out;
    }

    @keyframes fadeIn {
      from {
        opacity: 0;
      }
      to {
        opacity: 1;
      }
    }

    /* Show the modal when the "modal-show" class is added */
    .modal-show {
      display: block;
    }
    .modal form input {
        font-family: "Open Sans", sans-serif;
    }
    /* Define the blinking cursor animation */
    @keyframes blink {
      0% {
        opacity: 1;
      }
      50% {
        opacity: 0;
      }
      100% {
        opacity: 1;
      }
    }

    /* Apply the blinking cursor animation to the .cursor element */
    .cursor {
      animation: blink 0.7s infinite;
      font-weight: bold;
      /* display in line with the typewriter text */
        display: none;

    }

    #typewriterText {
        font-family: "Open Sans", sans-serif;
         width: 100%;
  height: 100%;
  display: flex;
  text-align: left;
  border: none;
  outline: none;
  font-size: 16px;
  font-weight: bold;
  color: #000;
  margin-top: -80px;
    }

      /* Container for the loading bar */
    .loading-bar-container {
      width: 95%; /* Set the desired width of the loading bar */
      height: 6px; /* Set the desired height of the loading bar */
      background-color: #E5E6E8; /* Set the background color to E5E6E8 */
      overflow: hidden; /* Hide the overflowing part of the loading bar */
      position: relative; /* Set the position to relative for child positioning */
      border-radius: 5px; /* Set the border radius to 5px */
      margin: 20px;
    }

    /* Loading bar with gradient and animation */
    .loading-bar {
      position: absolute; /* Position the bar within the container */
      left: -100%; /* Start position (completely hidden on the left) */
      width: 100%; /* Width of the loading bar */
      height: 100%; /* Height of the loading bar */
      background: linear-gradient(to right, #F22F46, #273556, #E5E6E8); /* Gradient colors */
      animation: slide 2s infinite; /* Animation to slide the bar */
      border-radius: 5px; /* Set the border radius to 5px */
    }
    /* Keyframes animation to slide the loading bar from left to right */
    @keyframes slide {
      from {
        left: -100%;
      }
      to {
        left: 100%;
      }
    }

    .gpt-loading {
        border-top: 3px solid rgb(228, 229, 233);
    }

    .modal-response__link {
        font-family: "Open Sans", sans-serif;
        /* add underlined text in twilio blue */
        color: #7C61F5;
        text-decoration: underline;
        margin-bottom: 6px;
        font-size: 15px;
        color: #008cff;
        opacity: 0.999;
        text-decoration: underline;
        padding: 0px;
    }
`;

var inputText = "Ask a question...";
var currentIndex = 0;
var typingSpeed = 60; // Typing speed in milliseconds

function clearInput() {
  document.getElementById("queryInput").value = "";
}

// Function to simulate typing one character at a time
function typeWriter() {
  if (currentIndex < inputText.length) {
    // Append the next character to the typewriter text
    document.getElementById("typewriterText").textContent +=
      inputText.charAt(currentIndex);
    currentIndex++;
    setTimeout(typeWriter, typingSpeed);
  } else {
    // When typing is complete, set the input placeholder to the final text
    document.getElementById("queryInput").placeholder = inputText;
    // Hide the typewriter text and cursor
    document.getElementById("typewriterText").style.display = "none";
    //document.querySelector(".cursor").style.display = "none";
  }
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
//const newLogoNavImg = chrome.runtime.getURL("logo-nav.svg");
const newLogoNavImg = chrome.runtime.getURL("gpt-docs-nav.png");

function darkenDom(b) {
  // assume that b is a boolean value that tells you whether to add or remove the overlay
  if (b) {
    // Create a new <div> element to serve as the overlay
    var overlay = document.createElement("div");
    // set the className
    overlay.className = "overlay-darken";

    // Set the CSS styles for the overlay
    overlay.style.position = "fixed"; // Fix the position of the overlay
    overlay.style.top = "0"; // Set the top position to 0
    overlay.style.left = "0"; // Set the left position to 0
    overlay.style.width = "100%"; // Set the width to 100% of the viewport
    overlay.style.height = "100%"; // Set the height to 100% of the viewport
    overlay.style.backgroundColor = "black"; // Set the background color to black
    overlay.style.opacity = "0.7"; // Set the opacity to create a semi-transparent effect
    overlay.style.zIndex = "9999"; // Set a high z-index value to place the overlay above other elements

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
  response.style.width = "100%";
  response.style.display = "flex";
  response.style.alignItems = "center";
  response.style.justifyContent = "center";
  response.style.padding = "0 20px";
  response.style.flexDirection = "column";
  response.style.textAlign = "left";
  response.style.borderTop = "3px solid #E4E5E9";
  // add a h2 element to the response div element
  var h2 = document.createElement("h2");
  h2.className = "h2";
  h2.style.width = "100%";
  h2.style.height = "100%";
  h2.style.display = "flex";
  h2.style.padding = "0 20px";
  h2.style.textAlign = "left";
  h2.style.fontSize = "18px";
  h2.style.fontWeight = "900    ";
  h2.style.color = "#000";
  h2.style.marginBottom = "20px";
  h2.style.marginTop = "20px";
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
  p.className = "p";
  p.style.width = "100%";
  p.style.height = "100%";
  p.style.display = "flex";
  p.style.padding = "0 20px";
  p.style.flexDirection = "column";
  p.style.textAlign = "left";
  p.style.fontSize = "16px";
  p.style.fontWeight = "normal";
  p.style.color = "#000";
  p.style.marginBottom = "20px";
  p.innerHTML = text;
  response.appendChild(p);

  // Create another h2 element that says "Sources"
  var h2 = document.createElement("h2");
  h2.className = "h2";
  h2.style.width = "100%";
  h2.style.height = "100%";
  h2.style.display = "flex";
  h2.style.padding = "0 20px";
  h2.style.textAlign = "left";
  h2.style.fontSize = "18px";
  h2.style.fontWeight = "900";
  h2.style.color = "#000";
  h2.style.marginBottom = "20px";
  h2.style.marginTop = "20px";
  h2.innerHTML = "Sources";
  response.appendChild(h2);

  // create a list of a links with the className .modal-response__link
  var ul = document.createElement("ul");
  ul.className = "modal-response__link";
  ul.style.width = "100%";
  ul.style.height = "100%";
  ul.style.display = "flex";
  ul.style.padding = "0 20px";
  ul.style.flexDirection = "column";
  ul.style.textAlign = "left";
  ul.style.fontSize = "16px";

  // loop through the links array
  for (var i = 0; i < links.length; i++) {
    // create a new list item element
    var newListItem = document.createElement("li");
    // set the className
    newListItem.className = "modal-response__link";
    // set the CSS styles
    newListItem.style.width = "100%";
    newListItem.style.height = "100%";
    newListItem.style.display = "flex";
    newListItem.style.padding = "0 20px";
    newListItem.style.flexDirection = "column";

    // create a new anchor element
    var newAnchor = document.createElement("a");
    // set the className
    newAnchor.className = "modal-response__link";
    // set the CSS styles
    newAnchor.style.width = "100%";
    newAnchor.style.height = "100%";
    newAnchor.style.display = "flex";

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
  // set the className
  wrap.className = "gpt-loading";
  // Set the CSS styles for the loader
  wrap.style.width = "100%";
  wrap.style.padding = "0 20px";

  // Create an h2 element that says "Gathering sources ..."
  var h2 = document.createElement("h2");
  h2.className = "h2";
  h2.style.width = "100%";
  h2.style.height = "100%";
  h2.style.display = "flex";
  h2.style.alignItems = "left";
  h2.style.justifyContent = "center";
  h2.style.padding = "0 20px";
  h2.style.flexDirection = "column";
  h2.style.textAlign = "left";
  h2.style.fontSize = "16px";
  h2.style.fontWeight = "bold";
  h2.style.color = "#000";
  h2.style.marginBottom = "20px";
  h2.style.marginTop = "20px";
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
  }, 1100); // Update interval to 5000ms (5 seconds)
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
    // Set the CSS styles for the modal
    modal.style.position = "fixed"; // Fix the position of the modal
    modal.style.top = "50%"; // Set the top position to 50% of the viewport
    modal.style.left = "50%"; // Set the left position to 50% of the viewport
    modal.style.width = "55%"; // Set the width to 300px
    modal.style.backgroundColor = "white"; // Set the background color to white
    modal.style.zIndex = "99999"; // Set a high z-index value to place the modal above other elements
    modal.style.borderRadius = "15px"; // Set a border radius
    modal.style.transform = "translate(-50%, -50%)"; // Center the modal
    modal.style.padding = "0px"; // Set some padding
    // Append the modal to the <body> element of the page
    modal.classList.add("modal-show");

    // Add a top bar to the modal
    var topBar = document.createElement("div");
    topBar.className = "top-bar";
    topBar.style.width = "100%";
    topBar.style.height = "50px";
    topBar.style.display = "flex";
    topBar.style.alignItems = "center";
    topBar.style.justifyContent = "space-between";
    topBar.style.padding = "0 20px";
    // add a close button to the right of the bar
    var close = document.createElement("span");
    close.className = "close";
    close.style.color = "black";
    close.style.fontSize = "30px";
    close.style.fontWeight = "bold";
    close.style.cursor = "pointer";
    close.innerHTML = "&times;";
    // make sure the close button is on the right
    close.style.marginLeft = "auto";
    // when the user clicks on the close button, remove the overlay

    // Add a title to the top bar
    var title = document.createElement("h2");
    title.className = "title";
    title.style.color = "black";
    title.style.fontSize = "20px";
    title.style.fontWeight = "bold";
    title.innerHTML = "GPT Docs";
    // ensure that the title appears in the middle of the top bar
    title.style.marginLeft = "auto";
    topBar.appendChild(title);
    // add a pill to the right of the title with experimental with a background of #f22f46 and and a color of a lighter version of that red
    var pill = document.createElement("span");
    pill.className = "pill";
    pill.style.backgroundColor = "rgba(242, 47, 70, 0.42)";
    pill.style.color = "#F22F46";
    pill.style.padding = "5px 10px";
    pill.style.marginLeft = "10px";
    pill.style.borderRadius = "5px";
    pill.style.fontSize = "12px";
    pill.style.fontWeight = "bold";
    pill.innerHTML = "Experimental";
    topBar.appendChild(pill);

    topBar.appendChild(close);
    modal.appendChild(topBar);

    // add a div element under the top bar to hold the content
    var content = document.createElement("div");
    content.className = "modal-content";
    content.style.width = "100%";
    //content.style.height = "100%";
    content.style.display = "flex";
    content.style.alignItems = "center";
    content.style.justifyContent = "center";
    // add 10px padding to the top and bottom of the content
    content.style.padding = "0 20px";
    // add a border to the top of #E4E5E9
    content.style.borderTop = "3px solid #E4E5E9";
    content.style.paddingTop = "23px";
    // add two div elements to the content div element one on the left and one on the right
    var left = document.createElement("div");
    left.className = "left";
    left.style.width = "5%";
    //left.style.height = "100%";
    left.style.display = "flex";
    left.style.alignItems = "center";
    left.style.justifyContent = "center";
    left.style.padding = "0 20px";

    var right = document.createElement("div");
    right.className = "right";
    right.style.width = "95%";
    //right.style.height = "100%";
    right.style.display = "flex";
    right.style.alignItems = "center";
    right.style.justifyContent = "center";
    //right.style.padding = "0 20px";

    // add a div element to the left div element
    var leftContent = document.createElement("div");
    leftContent.className = "left-content";
    leftContent.style.width = "100%";
    leftContent.style.height = "100%";
    leftContent.style.display = "flex";
    leftContent.style.alignItems = "center";
    leftContent.style.justifyContent = "center";
    leftContent.style.padding = "0 20px";
    leftContent.style.flexDirection = "column";
    leftContent.style.textAlign = "center";
    // add a h2 element to the left content div element
    // add the question.svg to the left content div element
    var question = document.createElement("img");
    question.className = "question";
    question.src = chrome.runtime.getURL("question.svg");
    question.style.width = "30px";
    question.style.height = "30px";
    question.style.maxWidth = "30px";
    question.style.marginBottom = "20px";
    leftContent.appendChild(question);

    // add left content to the left div element
    left.appendChild(leftContent);

    // add a div element to the right div element
    var rightContent = document.createElement("div");
    rightContent.className = "right-content";
    rightContent.style.width = "100%";
    rightContent.style.height = "100%";
    rightContent.style.display = "flex";
    rightContent.style.alignItems = "left";
    rightContent.style.justifyContent = "left";
    //rightContent.style.padding = "0 20px";
    rightContent.style.flexDirection = "column";
    rightContent.style.textAlign = "left";
    // add a query form to the right content div with "Ask a question.. " as the placeholder remove all the border and background stuff
    var form = document.createElement("form");
    form.className = "form";
    form.style.width = "100%";
    form.style.height = "100%";
    form.style.display = "flex";
    form.style.alignItems = "center";
    form.style.justifyContent = "center";
    form.style.padding = "0 5px";
    form.style.flexDirection = "column";
    form.style.textAlign = "center";
    form.style.marginTop = "-20px";
    // add a input element to the form element
    var input = document.createElement("input");
    input.className = "input";
    input.style.width = "100%";
    input.style.height = "100%";
    input.style.display = "flex";
    input.style.alignItems = "center";
    input.style.justifyContent = "center";
    //input.style.padding = "0 20px";
    input.style.flexDirection = "column";
    input.style.textAlign = "left";
    input.style.border = "none";
    input.style.outline = "none";
    input.style.fontSize = "16px";
    input.style.fontWeight = "bold";
    input.style.color = "#000";
    //input.style.marginBottom = "60px";
    input.id = "queryInput";
    input.autocomplete = "off";

    // add span id="typewriterText"></span><span class="cursor">|</span> to the input element
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

    //modal.appendChild(response);

    // add a close button to the modal

    close.addEventListener("click", function () {
      // remove the overlay div element

      document.querySelector(".overlay-darken").remove();
      // remove the modal div element
      document.querySelector(".modal").remove();
    });
    document.body.appendChild(modal);
    //typeWriter();
  }
}

// create a function to add an overlay modal to the page when the the user clicks on docs-nav__link
function addOverlay() {
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
  document.querySelector(".overlay").style.display = "block";

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

  ulElement.appendChild(newListItem);
} else {
  console.error(
    'Unable to find the unordered list element with class "docs-nav__secondary"'
  );
}

// append the newListItem to docs-nav__secondary between the 2nd and 3rd list item
ulElement.insertBefore(newListItem, ulElement.childNodes[5]);
