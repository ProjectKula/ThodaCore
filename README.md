# Thoda Core

Thoda Core serves as the backend for an unnamed exclusive social media platform for RVCE students. It is not yet intended for widespread usage.

Thoda Core is written in Swift. It uses Vapor as the server and provides GraphQL APIs. The backend uses a PostgreSQL database for persistent data storage and Redis for caching and token management.

Thoda Core is not a standalone app, but rather the backend for an app that will access Thoda Core through GraphQL. Thoda Core is designed to run seamlessly on Linux and macOS. Windows support may not be guaranteed.

## Contributions
Contributions and improvements are always welcome. Feel free to fork the repository, make changes, and submit pull requests.

1. Clone the repository
```
git clone https://github.com/cyberslothz/ThodaCore
```
2. Install dependencies
```
cd ThodaCore
swift package resolve
```
3. Start a PostgreSQL server on port 5432, with the username `postgres` and password `12345678`. Create a database `postgres`, if it doesn't already exist.
4. Run Redis on the default port.
5. Run all migrations. This will ensure you're running the latest database schema.
```
swift run App migrate
```
6. Run the app
```
swift run App
```
7. Use `http://127.0.0.1:8080/graphql` as the GraphQL endpoint.

## Lore
The name Thoda Core comes from `Thoda Aur`, one of the canteens at RVCE.
