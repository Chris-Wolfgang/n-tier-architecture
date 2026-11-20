# n-tier reference design

This folder explains the n-tier reference diagram,
[`docs/diagrams/n-tier Model Object Diagram.vsdx`](../diagrams/n-tier%20Model%20Object%20Diagram.vsdx)
([SVG export](../diagrams/n-tier%20Model%20Object%20Diagram.svg)). The diagram shows *what* the parts
are and how they connect; these pages hold the rules and the reasons behind them, so the diagram can
stay visual.

The design is a set of swappable modules: one `IService` contract with several implementations
(in-process, cached, remote over gRPC or Web API, fake), and repository contracts with several data
stores behind them. Several user interfaces and an ETL tool reuse the same modules and backend.

## Pages

Read them in this order the first time:

1. [Overview](overview.md): the deliverables on the diagram and the swap rule.
2. [Layers and dependency direction](layers.md): which project references which, and why.
3. [Legend](legend.md): what each colour, marker and line means.
4. [Views and diagram sources](views.md): the poster, the C4 views, and Visio vs Mermaid.

Sections still to be written (decided, recorded on
[#8](https://github.com/Chris-Wolfgang/n-tier-architecture/issues/8) and
[#23](https://github.com/Chris-Wolfgang/n-tier-architecture/issues/23)):

- Composition root and DI choices
- Error handling, errors on the wire, and validation
- Search, paging, concurrency, and the unit of work
- Remote proxies, resilience, and authentication
- Caching, observability, secrets, horizontal scaling, and tenancy
- Offline sync

## When the doc and the diagram disagree

The Visio file is the source of truth for now (see [Views and diagram sources](views.md)). Some pages
describe decisions that the diagram has not been redrawn for yet; each one says so and links the
diagram issue that tracks the redraw.
