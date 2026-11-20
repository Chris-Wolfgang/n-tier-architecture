# Legend

[Back to the index](README.md)

This table is the legend for the diagram. It describes the notation the diagram is being moved to;
the redraw is tracked in [#37](https://github.com/Chris-Wolfgang/n-tier-architecture/issues/37), so
the current SVG does not match every row yet.

| Element | Meaning |
|---|---|
| Light-blue box with **S1** | Implements `IService`. Any blue can be swapped for another blue. |
| Orange box with **RR / SR / WR** | Implements `IReadOnlyRepository` / `ISearchableRepository` / `IWriteOnlyRepository`. Swappable for any implementation with the same markers. Repository contracts (relational, document, `IUnitOfWork`) are also orange. |
| Background-worker box, «worker» | Runs on its own trigger or schedule and does not implement `IService`, for example `SyncService : ISyncService`. No S1 marker. |
| Plain component box | A supporting component that is neither a service nor a repository, for example `IAuthenticationClient` (sign-in). |
| Pale-blue region | Business Logic Layer |
| Pale-orange region | Data Access Layer |
| Container with a header | One deliverable, each with its own fill: Client Application (light grey), Web Service (pale teal), Web UI (pale green), Console ETL (lilac-blue). |
| Pale-orange panel | Repository catalog: the Relational and Document repository panels beside the diagram. |
| Lilac group with technology icons | UI technology options for the desktop client (Windows Desktop: WPF, WinUI 3, Windows Forms, BlazorWebView; Cross Platform: MAUI, Blazor Hybrid). The Web UI and Web Service show their options as icons inside the container. |
| Grey box | Data store |
| Yellow box | Note. Yellow is used for nothing else. |
| Dashed line, hollow triangle | Implements (UML realization), pointing at the interface |
| Solid black arrow | Calls or depends on, in process |
| Blue line labelled `«HTTPS / REST»` or `«gRPC»` | Call across the wire |
| Green dashed line | Offline sync: push the outbox, then pull changes |
| Diamond | DI registration, decided once at startup, never per call |
| Key icon | Holds secrets ([#35](https://github.com/Chris-Wolfgang/n-tier-architecture/issues/35)) |

**Rule:** colour is never the only signal. Every colour or line style also differs by a label, an icon
or a pattern, so the diagram still reads in greyscale and for colour-blind readers.

## What is not an `IService`

Two components that the current diagram draws in blue are not `IService` implementations
([#38](https://github.com/Chris-Wolfgang/n-tier-architecture/issues/38)):

- **`SyncService`** moves data between the client's SQLite database and the server. It becomes a
  background worker with its own `ISyncService`. Recording offline changes moves to
  `OutboxRepositoryProxy`, an orange WR decorator on the client's local repository.
- **`AuthenticationProxy`** is split into client sign-in (`IAuthenticationClient`), a
  `BearerTokenHandler` on the remote proxies' `HttpClient`, JWT bearer middleware in the Web Service
  host, and `ICurrentUser` in `Abstractions`. `AuthorizationProxy` stays blue as the first link of the
  `IService` chain.

The offline sync and authentication pages (still to be written) cover these in detail.
