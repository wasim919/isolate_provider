# Isolate

Background API fetching using Isolate and Provider.

## Features

-   API fetching and parsing is done inside of a Worker class which is a wrapper over Isolate

-   UI is updated through the communication between main Isolate, child/worker Isolate, Provider and the UI.

## Packages used

-   Provider
-   http
