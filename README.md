# Travlr Getaways (CS 465 Full Stack Development)

Travlr Getaways is a travel booking application built on the MEAN stack (MongoDB, Express, Angular, Node.js). It has two sides: a customer-facing website that shows available trips, and a secured administrator single-page application (SPA) for adding, editing, and deleting trips.

## What is in this repository

| Folder | What it holds |
|---|---|
| `app_server` | The customer website: Express routes, controllers, and Handlebars views and partials |
| `app_api` | The REST API: routes, controllers, Mongoose models (trips and users), and the Passport login setup |
| `app_admin` | The Angular admin SPA: components, services, models, routes, JWT interceptor, and route guard |
| `data` | `trips.json`, the seed data for the database |
| `public` | Static files such as images and CSS |

## How to run it

1. Start MongoDB.
2. In the main folder, run `npm install`, then `node app_api/models/seed.js` to load the trips, then `npm start`. The site and API run at http://localhost:3000 (the trips page is at `/travel`).
3. In a second terminal, go to `app_admin`, run `npm install`, then `ng serve`. The admin SPA runs at http://localhost:4200.
4. Create the first administrator by sending a POST request to `http://localhost:3000/api/register` with JSON that has `name`, `email`, and `password`. Then log in through the SPA.

A `.env` file with a `JWT_SECRET` value is needed for login. It is not stored in GitHub.

---

# Module Eight Journal

## Architecture

**Compare and contrast the types of frontend development you used in your full stack project, including Express HTML, JavaScript, and the single-page application (SPA).**

I used three different approaches, and each one made sense for a different job.

The customer site uses Express with Handlebars. The server asks the API for the trips, fills a template with the data, and sends back finished HTML. It is simple, it loads quickly, and search engines can read it. The downside is that every click means a brand new page from the server.

The second approach is plain JavaScript talking to a REST API. The Express API returns JSON, and any client can use it to build a page. That separates the data from how it looks. Both the customer site and the admin SPA call the same API, and that is why a change an administrator makes shows up for customers right away.

The third approach is the Angular SPA. It loads once, and after that Angular swaps components in the browser and only asks the server for data. That gave me things the Handlebars pages can't do easily, like live list updates after an edit, form validation before anything is sent, and buttons that appear only when you are logged in. The tradeoff is that it depends more on the browser and takes more setup. Using server-rendered pages for customers and an SPA for admins gave each group the style that fits it best.

**Why did the backend use a NoSQL MongoDB database?**

MongoDB stores data as JSON-like documents, so a trip is saved in nearly the same shape the API sends and Angular uses. I didn't have to translate between tables and objects. It was also easy to change as I went. I could add fields and change the trip model without rebuilding a schema, and Mongoose let me add structure back where I wanted it, like required fields and a unique trip code. Since the trips are mostly standalone records and not heavily connected to other data, a document database was a good fit.

## Functionality

**How is JSON different from JavaScript and how does JSON tie together the frontend and backend development pieces?**

JavaScript is a programming language. It has logic, functions, and variables. JSON is only a text format for data. It has no functions or logic, just names and values, and every key and string has to use double quotes. JSON looks like a JavaScript object, but it is really a plain text way of writing one down so it can be sent between programs.

JSON is what ties everything together. MongoDB stores documents that look like JSON, Mongoose turns them into JavaScript objects on the server, and the API sends them out with `res.json()`. The Handlebars controller and the Angular services both receive that same JSON and use it to build the page. Because the data keeps the same shape at every step, the layers fit together without conversion code.

**Provide instances in the full stack process when you refactored code to improve functionality and efficiencies, and name the benefits that come from reusable user interface (UI) components.**

I refactored several times:

- At first the customer travel page read `trips.json` straight from a file. I changed it to call the API, so the site and the admin SPA now share one source of truth in the database.
- I moved the models and API code into `app_api`, separate from the customer site in `app_server`, so each folder has one job.
- In Angular, all HTTP calls moved into one `TripDataService`, and all login logic moved into an `AuthenticationService`. Components don't repeat that code.
- I added an HTTP interceptor that attaches the token to every request, so I never had to add the header by hand in each call.
- I added an Angular route guard so the Add and Edit pages can't be opened by typing the URL when logged out.
- The Add and Edit forms build their inputs by looping over a list of fields, instead of repeating HTML for each one.
- During testing I fixed the update controller so it returns the updated trip with a 200 status, and I made the trip code unique and the price a number in the Mongoose schema.

Reusable UI components pay off in a few ways. The trip card is written once and used for every trip, so a design change happens in one place. The navbar, the header and footer partials in Handlebars, and the form components work the same way. That means less code, fewer bugs, and a consistent look, and a new feature can reuse a piece that already works.

## Testing

**Explain your understanding of methods, endpoints, and security in a full stack application.**

An endpoint is a URL the API listens on, like `/api/trips`. The method says what to do with it: GET reads, POST creates, PUT updates, and DELETE removes. The same URL can do different things depending on the method, and each response comes back with a status code such as 200, 201, 204, 400, 401, or 404 that tells the client what happened.

Testing is harder once security is added, because a request can fail for reasons that have nothing to do with the data. In my app, GET requests are public, but POST, PUT, and DELETE require a JSON Web Token. Passwords are stored as salted hashes, and the server checks the token on every protected call. I had to test the happy paths and the failures. To do that I wrote a small PowerShell function that sends a request and prints the status code. I ran 12 tests: reading trips, logging in, creating, updating, and deleting a trip, then rejected requests with no token, a fake token, a wrong password, missing fields, a duplicate code, and a trip that doesn't exist. Every result matched what I expected. On the Angular side, I checked that the SPA could GET and PUT data and that logging out sent me away from the protected pages. Testing both sides showed me that security has to be enforced on the server, because hiding a button in the browser isn't enough.

## Reflection

**How has this course helped you in reaching your professional goals? What skills have you learned, developed, or mastered in this course to help you become a more marketable candidate in your career field?**

This course took me from separate pieces to a complete application. I built a working full stack app from the database up to a secured admin interface, and I can now explain how every layer talks to the others. The skills I developed include building a REST API with Express and Mongoose, designing a MongoDB schema, using Handlebars templates, building an Angular SPA with components, services, routing, and reactive forms, and adding JWT authentication with Passport. I also got better at testing an API directly, using Git with a branch for each module, and writing a design document that explains the architecture to someone else. The biggest thing I learned is how to debug across layers, because a problem on screen can start in the browser, the API, or the database. Being able to build and explain a whole application, and having it in a GitHub portfolio, makes me a stronger candidate for full stack and web development roles.