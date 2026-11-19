# Views and diagram sources

[Back to the index](README.md)

## Views

The current diagram is an overview **poster**: it mixes several kinds of view on one sheet. It stays
as the at-a-glance picture, and C4 views are added as further pages of the same Visio file
([#39](https://github.com/Chris-Wolfgang/n-tier-architecture/issues/39)). Each view uses one notation,
has its own legend, and is written for a named reader.

| View | Notation | For |
|---|---|---|
| Poster (current sheet) | Mixed overview, with regions titled by view | Everyone, at a glance |
| System context (C4 level 1) | C4 | Stakeholders and new readers |
| Containers (C4 level 2) | C4, with protocol-labelled lines | Architects and operations: deliverables, data stores, Redis, the identity provider, one stamp per customer |
| Components (C4 level 3) | C4 | Developers: the `IService` chain and the DAL, drawn once |
| Code (C4 level 4) | UML class | Developers: interfaces, `ServiceResult<T>`, `Page<T>`, realization lines |
| Composition root | Table or option boxes, no diamonds | Developers: the DI choices made once at startup |
| Sequences | UML sequence, in these pages | Offline sync, sign-in and token refresh, a request across the wire that fails |

Rules:

- **One notation per view.** Flowchart diamonds appear only in a flowchart, never in a structural view.
- **Each view says what it is and links to the others.** These pages introduce each view in a sentence
  before showing it.

## Diagram sources

- **Visio is the source of truth for now**, for the poster and for the C4 pages. The SVGs are exported
  with `scripts/Export-DiagramSvg.ps1`.
- **Every view also gets a Mermaid version**, written inline in these pages so it renders on GitHub
  with no tooling:
  - C4 context, containers and components: Mermaid C4;
  - code: `classDiagram`;
  - sequences: `sequenceDiagram`;
  - composition root: a Markdown table.
- **Trial:** [#40](https://github.com/Chris-Wolfgang/n-tier-architecture/issues/40) defines what
  "fits the bill" means. If Mermaid passes, it becomes the source of truth and the Visio file is
  archived or kept for the poster only. If not, Visio stays, and Structurizr DSL is the fallback for
  the C4 views.

While both exist:

- **Visio wins** when the two disagree.
- A PR that changes a view updates the Visio file, its exported SVG **and** the matching Mermaid block
  together.
- The Visio file is binary, so diagram changes go in one Visio pass at a time, never in parallel PRs.
