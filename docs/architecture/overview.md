# Overview

[Back to the index](README.md)

## The deliverables

The diagram has four containers. Each one is a separate deliverable, built and deployed on its own.

| Container | What it is | Has its own BLL and DAL? |
|---|---|---|
| Client Application | Desktop app: WPF, WinUI 3, Windows Forms, BlazorWebView, MAUI or Blazor Hybrid | Yes, so it can work offline against SQLite |
| Web UI | MVC, Razor, Blazor, Blazor Server or React | No. It calls the Web Service. |
| Web Service | The backend: Minimal API, Controller API or gRPC host | Yes. This is the only tier that touches the server databases. |
| Console ETL | Batch loads | No. It always calls the Web Service, so the server's business rules and authorization apply to every load. |

## The swap rule

Every box that implements `IService` (light blue, **S1** marker) can be replaced by any other box
that implements it:

- `Service`: the real business logic;
- `AuthorizationProxy`, `ValidationProxy` and `ServiceCacheProxy`: decorators around `Service`;
- `GrpcRemoteProxy` and `WebApiRemoteProxy`: call the Web Service across the wire;
- `FakeService`: canned data for tests and UI work.

Repositories follow the same rule (orange, **RR / SR / WR** markers): any implementation with the same
markers can replace another, for example `EFRepository`, `DapperRepository`, `RepositoryCacheProxy`
or `FakeRepository`.

The caller never knows which implementation it has. A UI that calls `IService` works the same whether
the call stays in process, goes through a cache, or crosses the wire.

## The choices are made once, at startup

The diamonds on the diagram ("Use fakes?", "Cache Enabled?", "In-process?", "Use gRPC?") are not
runtime `if` statements. Each one is answered once, in the host's composition root (`Program.cs` or
the host builder), by registering a different implementation in DI. Production code never asks about
the environment. The composition-root page (still to be written) covers this in detail.

## Storage is chosen per aggregate

Each aggregate has its own repository and store, for example a cart in a document database and an
order in a relational one. The storage model is chosen at design time and stays fixed:

- **Relational** (SQL Server, PostgreSQL, MySQL, MariaDB, SQLite): EF or Dapper. Switching product
  means changing the provider and the connection string.
- **Document** (Cosmos DB, MongoDB, CouchDB): switching product means rewriting the repository.
