# Hypermedia APIs: HATEOAS and Its Applications

API7.ai

August 7, 2025

[API 101](https://api7.ai/learning-center/api-101)

## Key Takeaways

- **Discoverable APIs:** Hypermedia APIs use embedded links (hypermedia) in responses to guide clients, reducing reliance on hardcoded endpoints and external documentation.
- **HATEOAS Principle:** This REST constraint ensures that clients interact with an application solely through hypermedia provided by the server.
- **Benefits:** Key advantages include enhanced API self-description, reduced client-server coupling, improved consistency, and greater evolvability, making APIs more maintainable.
- **Implementation:** Employing standards like HAL or JSON

and designing for discoverability by including links for navigation and actions are crucial.
- **API Gateway Role:** Gateways can assist in enforcing hypermedia standards, dynamically generating links, and enhancing security for hypermedia-driven actions.

## Introduction

In the intricate tapestry of modern software architecture, building APIs that are not only functional but also adaptable and discoverable is paramount. [RESTful API](https://api7.ai/learning-center/api-101/restful-api-best-practices) design principles have evolved significantly, moving beyond simple data retrieval to embrace more dynamic and intelligent interaction models. At the forefront of this evolution are **Hypermedia APIs**, and the guiding principle known as **HATEOAS (Hypermedia as the Engine of Application State)**.

Coined by Roy Fielding, a foundational figure in the HTTP specification, HATEOAS represents a core constraint of the REST architectural style. It advocates for APIs that intrinsically guide clients through available actions and resources by embedding links and contextual data within their responses, rather than forcing clients to rely on external, often brittle, documentation.

This article will delve into the essence of hypermedia APIs and HATEOAS, explore their profound benefits, and showcase their practical applications for developers and API architects striving to build more resilient and future-proof systems.

## What are Hypermedia APIs and HATEOAS?

At its core, the concept of a **Hypermedia API** is straightforward: it's a RESTful API that uses hypermedia – think links, forms, and other interactive controls – embedded within its responses to guide clients on what actions they can perform next. This approach is deeply rooted in the **HATEOAS (Hypermedia as the Engine of Application State)** principle, which is a fundamental constraint of the REST architectural style. Roy Fielding, one of the principal authors of the HTTP specification, emphasized that for an API to be truly RESTful, clients must be able to interact with the application solely through hypermedia provided within the responses.

This means that instead of a client developer needing to memorize specific API endpoints for different operations, or needing to consult extensive external documentation to understand how to transition from one state to another, the API itself provides this guidance. When a client requests a resource, the server's response includes not just the data, but also links that indicate possible next steps. For example, if a client retrieves an order, the response might contain a link to "track shipment" or "cancel order," along with the necessary URIs and potentially even schema information for how to perform those actions. This dynamic discovery mechanism reduces the need for clients to hardcode API paths, fostering a more adaptable and less brittle client-server relationship. The API becomes self-documenting and self-explaining through its hypermedia controls.

```
sequenceDiagram
    participant Client
    participant Server

    Client->>Server: GET /orders/123
    Server-->>Client: 200 OK - Order Details with _links (self, cancel_order, customer)
    Client->>Client: Parse response, find 'cancel_order' link
    Client->>Server: POST /orders/123/cancel (using link from response)
    Server-->>Client: 200 OK - Order Cancelled, _links for updated status
```

## Why Embrace Hypermedia APIs and HATEOAS?

The adoption of HATEOAS and hypermedia in API design is not merely an academic exercise; it offers tangible, significant advantages that directly contribute to the longevity, maintainability, and overall robustness of software systems. By embedding the intelligence about available actions and state transitions within the API responses, HATEOAS promotes a more loosely coupled architecture where the server dictates the application's flow, rather than the client needing to pre-emptively know it all.

Let's explore the compelling reasons why embracing this architectural style is beneficial:

- **Self-Descriptive APIs and Enhanced Discoverability:** This is perhaps the most significant benefit. In a HATEOAS-compliant API, clients aren't burdened with remembering or discovering every single endpoint. When a client requests a resource, the response itself contains hyperlinks that clearly indicate related resources and available actions. For instance, a `GET /orders/123` response might link to `/orders/123/items`, `/customers/456`, and actions like `/orders/123/cancel` or `/orders/123/pay`. This makes the API inherently easier to understand and use, reducing the learning curve for developers integrating with your system. It's like navigating a website where every page has links to related content and actions, rather than needing a sitemap and manual for every interaction. Companies that effectively leverage these principles can see up to a **40% reduction in client-side API integration complexity**, according to industry analyses.

- **Reduced Client-Server Coupling and Increased Evolvability:** The loose coupling facilitated by HATEOAS is crucial for long-term maintainability. If the server-side URI structure changes, or new actions are introduced, clients that adhere to the hypermedia controls don't necessarily break. As long as the server provides updated links in its responses, clients can adapt dynamically. Imagine a scenario where a company wants to change the URI for cancelling an order from `/orders/{id}/cancel` to `/order-management/v2/orders/{id}/initiate-cancellation`. If the client is using the `rel="cancel_order"` link provided in the HATEOAS response, it will simply follow the new URI provided by the server, without needing any code changes. This agility is invaluable in fast-paced development environments.

- **Improved Consistency and Uniformity in Interface Design:** HATEOAS promotes a uniform interface for interacting with resources, particularly for state transitions and actions. By standardizing how actions are represented (e.g., always using a link with a specific `rel` attribute for a particular action), APIs become more predictable and intuitive. This consistency reduces ambiguity for client developers and makes the API feel more cohesive. For example, all "update" actions might consistently use a link with `rel="edit"` and specify the appropriate HTTP method (e.g., PUT or PATCH).

- **Future-Proofing Your API Investments:** By decoupling the client from specific URI structures and making the API discoverable, HATEOAS acts as a natural form of future-proofing. As your application evolves and backend systems are refactored, the API remains stable from the client's perspective as long as the hypermedia links are managed correctly on the server side. This reduces the ongoing cost of maintenance and the risk associated with API changes, allowing businesses to innovate with greater confidence. Fielding himself emphasized this, stating, "A REST API should be entered with no prior knowledge beyond the initial URI… The rest of the interaction is driven by hypertext."


In essence, adopting HATEOAS shifts the locus of control and knowledge towards the server, making the API more intelligent, self-descriptive, and resilient to change. This leads to more robust applications, faster development cycles for new features, and a significantly reduced burden on client developers over time.

## Implementing Hypermedia APIs: Concepts and Best Practices

Successfully implementing a HATEOAS-compliant API involves a thoughtful approach to design, leveraging established hypermedia standards, and understanding how to embed contextual information effectively within API responses. It requires a mindset shift towards making the API its own guide.

**Core Concepts to Understand:**

1. **Links are Paramount:** The foundation of hypermedia is the **link**. In a RESTful context, a link is typically represented as a set of key-value pairs, most importantly containing:
   - `href`: The Uniform Resource Identifier (URI) of the resource or action.
   - `rel`: The relationship term that describes the purpose or nature of the link. This is crucial for discoverability. Examples: `self`, `next`, `previous`, `edit`, `delete`, `view_details`.
   - Other attributes can include `method` (e.g., GET, POST, PUT), `type` (media type of the resource), `title` (a human-readable description), and `hreflang` (language of the linked resource).
2. **Representing Actions Beyond Simple Navigation:** HATEOAS isn't just about linking to existing resources; it's also about exposing the _actions_ that can be performed on those resources or in response to their current state. These actions are represented by links with descriptive `rel` values. For state-changing operations, the link might also include the HTTP method and potentially a `type` indicating the expected request payload format.

3. **Embedding Related Resources:** To reduce the number of round trips a client needs to make, hypermedia standards often allow for embedding related resources directly within the main resource's response. For example, an order resource could embed its associated line items. This is often done within a dedicated `_embedded` or `embedded` section in the response. However, this must be balanced against potential increases in payload size.


**Leveraging Hypermedia Standards for Structure and Interoperability:**

While you _can_ invent your own hypermedia structures, using established standards significantly improves interoperability between different clients and servers.

- **HAL (Hypertext Application Language) (`application/vnd.hyper+json`):**
HAL is a simple, widely adopted convention for creating a structured way to represent links and embedded resources in JSON. It typically uses:
  - `_links`: An object containing all links, keyed by their `rel` attribute.
  - `_embedded`: An object containing embedded resources, keyed by a name representing the relationship.
  - _Example of HAL link:_`"self": { "href": "/orders/123" }`
  - _Example of HAL action:_`"cancel_order": { "href": "/orders/123/cancel", "method": "POST" }` [This blog](https://www.javacodegeeks.com/2025/05/beyond-the-defaults-crafting-custom-_links-structures-with-spring-hateoas.html) discusses how Spring HATEOAS typically serializes links into a JSON object nested under the `_links` key, with each link represented by its relation (rel).
- **JSON**


**(`application/vnd.api+json`):**
JSON

is a more opinionated specification that defines a strict set of rules for building JSON APIs, including how to represent resources, relationships, attributes, and links. It offers a highly structured and consistent way to build hypermedia APIs. It emphasizes:

  - `links`: Includes links for the resource itself, related resources, and pagination.
  - `data`: The primary resource object.
  - `attributes`: Resource properties.
  - `relationships`: Links to related resources.
  - _Example of JSON_

    _link:_`"links": { "self": "/articles/1" }`
- **Collection+JSON (`application/vnd.collection+json`):**
This standard is specifically designed for representing collections of resources and includes mechanisms for links related to the collection itself (e.g., pagination) and for the items within the collection.


**Best Practices for Design and Implementation:**

1. **Design for Discoverability from the Outset:** As you design your API resources, consider the entire lifecycle and potential interactions. For every resource representation, ask: What can a client _do_ with this resource _now_? What other resources are directly related?
   - **`self` Link:** Always include a `self` link pointing to the resource's URI.
   - **Collection Navigation Links:** For collection endpoints (e.g., `/orders`), include links for pagination: `next`, `prev`, `first`, `last`.
   - **Action Links:** For resources tied to a workflow, include links that represent valid state transitions. If an order can be paid, invoice paid, shipped, or cancelled, provide distinct links for these actions, possibly with descriptive `rel` values like `pay_invoice`, `track_shipment`, `cancel_order`. Include the appropriate HTTP method for these action links.
   - **Related Resource Links:** If a resource relates to another (e.g., an order to a customer), provide a link to that related resource with a descriptive `rel` like `customer` or `customer_details`.
   - **Embedding Strategy:** For tightly coupled or frequently accessed related data (like order line items within an order response), consider embedding them to reduce client round-trips. Be mindful of payload size and only embed what is commonly needed together.
2. **Use Clear, Meaningful, and Standardized `rel` Attributes:** The `rel` attribute is the semantic heart of a hypermedia link; it tells the client what the link is for.
   - **Standard Relations:** For common patterns like navigation (`next`, `prev`) or resource types (`customer`, `product`), use established link relation types where appropriate (e.g., from IANA's Link Relation Types registry).
   - **Custom Relations for Actions:** For application-specific actions, define clear, descriptive custom `rel` values. Avoid cryptic abbreviations. Instead of `rel="p"`, use `rel="pay_invoice"`. Instead of `rel="edit"`, perhaps `rel="update_profile"` if that's more specific.
   - **Namespace Custom Relations:** To avoid conflicts with standard relation types, especially if building a large, complex API, consider namespacing custom relations (e.g., `my-api:add-to-cart`).
3. **Structure Responses Consistently:** Whether you choose HAL, JSON


, or a custom structure, ensure consistency across all your API endpoints. A well-structured response makes it easier for clients to parse and utilize the hypermedia.


Here's an example demonstrating a HAL-like structure for an order with embedded line items and action links:



```json
{
     "id": "ORD-789",
     "order_date": "2023-10-27T10:00:00Z",
     "total_amount": 150.75,
     "status": "PROCESSING",
     "_links": {
       "self": { "href": "/orders/ORD-789" },
       "customer": { "href": "/customers/CUST-456" },
       "invoice": { "href": "/invoices/INV-101" },
       "cancel_order": {
         "href": "/orders/ORD-789/cancel",
         "method": "POST",
         "title": "Cancel this order"
       },
       "update_shipping": {
         "href": "/orders/ORD-789/shipping",
         "method": "PUT",
         "title": "Update shipping details"
       }
     },
     "_embedded": {
       "order_items": [\
         {\
           "id": "ITEM-001",\
           "product_id": "PROD-ABC",\
           "quantity": 2,\
           "item_price": 50.00,\
           "_links": {\
             "self": { "href": "/orders/ORD-789/items/ITEM-001" },\
             "product": { "href": "/products/PROD-ABC" }\
           }\
         },\
         {\
           "id": "ITEM-002",\
           "product_id": "PROD-XYZ",\
           "quantity": 1,\
           "item_price": 50.75,\
           "_links": {\
             "self": { "href": "/orders/ORD-789/items/ITEM-002" },\
             "product": { "href": "/products/PROD-XYZ" }\
           }\
         }\
       ]
     }
}
```

4. **Consider Type and Schema for Actions:** For links that represent actions requiring input (like updating shipping details or adding to a cart), you can include `method` and `type` attributes. For more complex inputs, you might even include a `schema` or `templated` URL to describe the required parameters, similar to how OpenAPI (Swagger) works.

5. **Build Generic Clients or Leverage Libraries:** To truly benefit from HATEOAS, build client applications that are hypermedia-aware. Instead of hardcoding URIs, the client parses the response, finds links based on their `rel` attributes (e.g., finding the link with `rel="cancel_order"`), and then uses the provided `href` and `method` to make subsequent requests. Many programming languages have libraries that can help parse HAL or JSON


    responses and manage hypermedia navigation.


## Applications of Hypermedia APIs and HATEOAS

The principles of HATEOAS and hypermedia are particularly powerful in scenarios demanding flexibility, evolving interfaces, and a reduced burden on client developers needing to understand complex, stateful workflows.

- **Content Management Systems (CMS) and Backends:** In a CMS, managing articles, pages, user profiles, or media items involves various states and possible actions. A HATEOAS-compliant API can expose links directly within a resource response for actions like "edit," "publish," "unpublish," "delete," or "view analytics." For a content editor, this means they can see exactly what actions are permissible for a given piece of content at any time, directly from the API response, making the editing interface dynamic and responsive to content state.

- **E-commerce Platforms:** The customer journey in e-commerce provides a rich ground for HATEOAS. Consider an order placed by a customer:
  - An initial order response might include links like `self` (for the order details), `customer` (to view customer info), `invoice` (to download an invoice), and potentially actions like `cancel_order` (if within the cancellation window).
  - If the order status changes to "shipped," the links might update to include `track_shipment` (with a URI pointing to a shipping carrier's tracking page or an internal tracking service) and remove the `cancel_order` link.
  - For product listings, links could be `add_to_cart`, `add_to_wishlist`, `view_details`, and `compare_product`. This allows the e-commerce front-end to dynamically render buttons and links based on the current state and available actions, rather than relying on hardcoded logic for every possible scenario.
- **Workflow and State Machine Management:** Many business processes involve distinct states and transitions (e.g., order fulfillment, loan application processing, user onboarding). HATEOAS naturally models these workflows. Each API response representing a resource in a particular state can provide links to the next valid transitions.
  - For example, an application in the "Draft" state might link to `/applications/{id}/submit` or `edit_application`. Once "Submitted," it might link to `/applications/{id}/status` or `view_status`. This makes the workflow flow discoverable and manageable via the API itself.
- **Resource Collections and Dynamic Pagination:** When dealing with large collections of data, HATEOAS provides an elegant solution for pagination. A response for `/products` that returns a collection might include `next`, `prev`, `first`, and `last` links, indicating the URIs for fetching other pages of results. This eliminates the need for clients to calculate page numbers or offsets, making pagination logic reusable and robust.

- **Generic API Clients and Tooling:** The principles of HATEOAS lend themselves to building generic API clients or tools. An application could be built that consumes _any_ HATEOAS-compliant API. Such a client would parse the links, understand their `rel` attributes, and present a consistent interface for interacting with different backend services, drastically reducing the need for API-specific client development. This concept is akin to how web browsers navigate the internet using hyperlinks.

- **Modernizing Legacy Systems (API Facades):** For organizations with existing legacy systems, exposing their functionalities through a modern hypermedia API can be a strategy for gradual modernization. The API facade can translate legacy operations into HATEOAS-driven interactions, making the underlying system more discoverable and adaptable without a complete overhaul.


## Challenges and Considerations for Hypermedia Adoption

While the advantages of HATEOAS are significant, its adoption is not without its challenges. A pragmatic approach requires understanding these hurdles:

- **Increased Payload Size:** Embedding detailed links, relationships, and potentially schemas within every API response naturally increases the size of the payload compared to a minimalist API that only returns data. For APIs where every byte counts (e.g., low-bandwidth mobile environments), this increased payload needs to be carefully managed. Strategies like using efficient standards (e.g., HAL over overly verbose custom structures) and judicious use of embedded resources are key.
- **Client Development Complexity and Initial Investment:** Building client applications that are truly hypermedia-aware requires a different way of thinking about API interactions. Developers must learn to parse the hypermedia controls and dynamically determine the next steps, rather than relying on hardcoded URIs. While this investment pays off in the long run through reduced maintenance, the initial learning curve and development effort can be higher.
- **Developer Education and Buy-in:** HATEOAS is a pattern that may be unfamiliar to many developers. Effectively communicating its benefits and providing training or clear examples is essential to gain team adoption and ensure consistent implementation across services.
- **Tooling and Framework Support Maturity:** Although standards like HAL and JSON

are well-defined, the ecosystem of libraries, frameworks, and tooling that fully supports generating, parsing, and utilizing hypermedia can vary in maturity across different programming languages and platforms. Ensuring your chosen stack has adequate hypermedia support is vital.
- **When is it Overkill?** For very simple, static APIs with predictable interactions (e.g., a fixed set of read-only endpoints), the overhead of implementing full HATEOAS might outweigh the benefits. In such cases, a more direct, RPC-style URI structure might be simpler and more appropriate. The decision to adopt HATEOAS should be driven by the anticipated complexity, need for evolvability, and desire for discoverability in your specific application domain.

## How API Gateways Fit into the Hypermedia Picture

While HATEOAS is fundamentally a client-server interaction design pattern at the API payload level, an **API gateway** can play a significant role in facilitating its implementation and enhancing the experience of consuming hypermedia APIs.

This diagram shows how an API gateway simply routes requests and responses without ever altering the hypermedia links, letting the client drive the flow entirely through HATEOAS.

```
sequenceDiagram
    Client->>Gateway: GET /orders/123
    Gateway->>Orders: forward
    Orders-->>Gateway: 200 + HAL links
    Gateway-->>Client: 200 + HAL (untouched)
    Client->>Gateway: follow link → /payments/123
    Gateway->>Payments: forward
    Payments-->>Gateway: 200 + next links
    Gateway-->>Client: 200 + HAL (untouched)
```

- **Enforcing Hypermedia Standards and Consistency:** An API gateway can be configured to validate that responses from backend services adhere to a specified hypermedia standard (e.g., expecting HAL or JSON


structures). This acts as a quality control mechanism, ensuring that all services contributing to the API facade maintain a consistent hypermedia interface. This is particularly useful in microservices architectures where multiple teams might be developing different services.

- **Dynamic Link Generation and Augmentation:** For common hypermedia elements like `self` links or pagination links (`next`, `prev`), an API gateway can sometimes be configured to inject these dynamically into responses. This can offload some of the hypermedia generation burden from individual backend services, particularly useful when wrapping legacy microservices that may not natively support HATEOAS. The gateway can construct these links based on the incoming request and the backend response, ensuring consistency.

- **Facilitating Generic API Clients:** By acting as a unified gateway that exposes a well-defined hypermedia API facade, it becomes easier for client developers to build generic clients. A client can interact with the gateway, which then intelligently routes requests to the appropriate backend service, all while maintaining the hypermedia contract. This abstraction enhances the client's longevity.

- **Security and Action Enforcement:** If specific hypermedia links represent critical actions (e.g., `cancel_order` or `process_payment`), an API gateway can be configured to enforce security policies (authentication, authorization, rate limits) specifically for those URI patterns, adding an extra layer of control and security around state-changing operations. For example, a `POST` request to a `/cancel_order` URI exposed via the gateway could be blocked if the user making the request is not authorized or if the rate limit for cancellations has been reached.


Below is a diagram showing how an API gateway can work with hypermedia:

```
sequenceDiagram
    participant Client
    participant API_Gateway
    participant Backend_Service_A
    participant Backend_Service_B

    Client->>API_Gateway: GET /orders/123
    API_Gateway->>Backend_Service_A: Forward request for order 123
    Backend_Service_A-->>API_Gateway: Order data with HAL links (self, cancel, customer)
    API_Gateway->>API_Gateway: Augment response with 'next' link for collection
    API_Gateway->>API_Gateway: Enforce security on 'cancel' action link
    API_Gateway-->>Client: 200 OK - Order data with enhanced HAL links

    Client->>API_Gateway: POST /orders/123/cancel (uses link from response)
    API_Gateway->>Backend_Service_A: Forward POST request for cancellation
    Backend_Service_A-->>API_Gateway: 200 OK - Order cancelled, status updated
    API_Gateway-->>Client: 200 OK - Success message with updated links
```

This demonstrates how the gateway acts as an intelligent intermediary, enhancing the hypermedia experience and ensuring consistent application of policies.

## Conclusion: Building Evolvable and Discoverable Systems with Hypermedia APIs

**Hypermedia APIs**, guided by the robust principles of **HATEOAS**, offer a sophisticated and mature approach to RESTful API design that significantly enhances discoverability, maintainability, and evolvability. By embedding contextual links and actionable controls directly within API responses, HATEOAS-driven APIs empower clients to dynamically navigate application states and discover available operations, thereby reducing dependencies on hardcoded URIs and external documentation. This leads to more resilient, adaptable, and maintainable systems that can better withstand the inevitable changes in backend architecture.

While challenges such as increased payload size and the initial client-side development investment exist, the long-term benefits of reduced coupling, improved API consistency, and inherent future-proofing often outweigh these considerations, especially for complex or evolving applications. Adopting established hypermedia standards like HAL or JSON

and focusing on clear, descriptive relation terms are key to maximizing these benefits. Furthermore, **[API gateways](https://api7.ai/learning-center/api-gateway-guide/what-is-an-api-gateway)** can play a crucial role in facilitating HATEOAS adoption by enforcing standards, dynamically augmenting responses with common hypermedia elements, and securing state-changing actions.

For developers and organizations committed to building high-quality, adaptable software solutions, understanding and implementing hypermedia principles is not just a best practice, but a strategic advantage. It fosters a more intelligent, state-driven interaction model that truly embodies the RESTful vision, transforming APIs into discoverable engines of digital business. By embracing HATEOAS, you are investing in the future adaptability and maintainability of your API ecosystem.

## Next Steps

Stay tuned for our upcoming column on the API 101, where you'll find the latest updates and insights!

Eager to deepen your knowledge about API gateways? Follow [our Linkedin](https://sg.linkedin.com/company/api7-ai) for valuable insights delivered straight to your inbox!

If you have any questions or need further assistance, feel free to contact [API7 Experts](https://api7.ai/contact).

Share article link

[English](https://api7.ai/learning-center/api-101/hypermedia-apis) [Español](https://api7.ai/es/learning-center/api-101/hypermedia-apis) [Français](https://api7.ai/fr/learning-center/api-101/hypermedia-apis) [Deutsch](https://api7.ai/de/learning-center/api-101/hypermedia-apis) [日本語](https://api7.ai/ja/learning-center/api-101/hypermedia-apis) [한국어](https://api7.ai/ko/learning-center/api-101/hypermedia-apis) [Português](https://api7.ai/pt/learning-center/api-101/hypermedia-apis) [العربية](https://api7.ai/ar/learning-center/api-101/hypermedia-apis) [Русский](https://api7.ai/ru/learning-center/api-101/hypermedia-apis) [हिन्दी](https://api7.ai/hi/learning-center/api-101/hypermedia-apis) [Bahasa Indonesia](https://api7.ai/id/learning-center/api-101/hypermedia-apis)