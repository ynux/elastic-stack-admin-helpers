# elastic-stack-admin-helpers
## What these script help with

For a start, I put some scripts to help with the administration of watches. Watcher is a licensed product of elastic, soon to be renamed to Alerting. https://www.elastic.co/guide/en/watcher/current/index.html

These shell scripts help with spooling and updating watches. There is no support for creating of json editing yet, this shouldn't be done in shell, I think. We have plans to write python scripts for this, and ultimately, a frontend application.

## Watcher and Testing
When creating watches, we recommend creating a test document at the same time, as something like a unit test. 

