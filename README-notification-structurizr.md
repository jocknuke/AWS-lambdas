# Internal Notification Platform - Structurizr Workspace

Files:
- `notification-service-architecture.dsl` - full Structurizr DSL workspace

## What is included
- System context view
- Container view
- Component view for the Notification API
- Dynamic request flow view
- Production deployment view

## Open locally with Structurizr Lite
Structurizr Lite uses a `workspace.dsl` file in a local workspace folder, and the official docs show it can be run with Docker by mounting that folder and opening `http://localhost:8080`. It can also use a custom filename via `STRUCTURIZR_WORKSPACE_FILENAME`. citeturn926192search1turn926192search7turn926192search10

### Option 1: easiest
1. Create a folder, for example `C:\structurizr\notification-platform`
2. Copy `notification-service-architecture.dsl` into that folder
3. Rename it to `workspace.dsl`
4. Run:

```bash
docker run -it --rm -p 8080:8080 -v C:\structurizr\notification-platform:/usr/local/structurizr structurizr/lite
```

5. Open `http://localhost:8080`

### Option 2: keep the filename as-is

```bash
docker run -it --rm -p 8080:8080 -v C:\structurizr\notification-platform:/usr/local/structurizr -e STRUCTURIZR_WORKSPACE_FILENAME=notification-service-architecture structurizr/lite
```

## Notes
- The workspace follows Structurizr DSL workspace/view structure from the official DSL docs. citeturn926192search2turn926192search3turn926192search18
- The deployment view syntax is based on Structurizr deployment environment and `containerInstance` patterns from the official docs. citeturn167614view0turn167614view1
