# GPT-Docs for Twilio Docs

### Disclaimer
<small>This code does not represent, nor is it affiliated with, any official project or initiative of Twilio company. This is not an officially sponsored, endorsed, or approved by the company. It is provided "as is" without any warranties or guarantees. </small>

![](/screenshots/query_resp_screenshot.png)

### Plan

We plan to crawl all the public twilio doc pages and then expose a q&a type interface to ask questions against the twilio docs. 

**Web Crawling**

- [x] Develop a web crawler that is capable of traversing and scraping all publicly accessible Twilio documentation pages.
- [x] Ensure the web crawler adheres to the "robots.txt" file and respects website access restrictions.
- [x] Extract and store relevant information from the documentation pages, including page content, titles, URLs, and any other metadata.

**Text Embedding**

- [x] Implement a text-embedding algorithm or utilize an existing embedding model to convert the crawled Twilio documentation content into vector representations (embeddings).
- [x] Ensure the embedding process maintains the context and semantics of the documentation content.

**Indexing Embeddings**

- [x] Store and manage the generated embeddings.
- [x] Implement an upsertion process to efficiently insert or update the embeddings into the index, along with their associated metadata.
- [x] Ensure the index is optimized for querying and retrieval of similar or relevant content based on user queries.

**Q&A Interface**

- [x] Design and implement an API that allows users to ask questions in natural language and receive answers based on the Twilio documentation content.
- [x] Integrate GPT-4 or a similar language model into the API to enhance the question-answering capabilities.
- [x] Implement a query mechanism that retrieves the most relevant documentation content from the index based on user queries and uses GPT-4 to generate human-like responses.
- [x] Ensure the API provides accurate and helpful answers to user questions in real-time.


**Todo**
- [ ] Consider other places to crawl beyond docs.

