workspace "Internal Notification Platform" "C4/Structurizr architecture for an internal notification platform that sends email and creates ServiceNow tickets, with future Microsoft Teams support." {

    !identifiers hierarchical

    model {
        requester = person "Internal Application / Job Owner" "Owns internal systems and support processes that trigger notifications."
        supportTeam = person "Operations Support Team" "Receives operational emails and works incidents."
        platformTeam = person "Platform Support Team" "Operates the notification platform and monitors delivery health."

        producerSystems = softwareSystem "Internal Producer Systems" "Oracle packages, SQL Server jobs, Java applications, .NET services, batch jobs, and automation workflows that submit notification requests."
        entra = softwareSystem "Microsoft Entra ID" "Identity provider used by the platform to obtain OAuth tokens for Microsoft Graph."
        graph = softwareSystem "Microsoft Graph" "API used to send email and, later, Teams messages."
        exch = softwareSystem "Exchange Online Mailboxes" "Mailbox infrastructure used to deliver outbound email from the service account or shared mailbox."
        servicenow = softwareSystem "ServiceNow" "ITSM platform where the service creates incidents or tasks."
        teams = softwareSystem "Microsoft Teams" "Future collaboration channel for notifications."
        corpIdentity = softwareSystem "Corporate Identity / API Access" "Enterprise authentication and authorization for internal callers."

        notification = softwareSystem "Internal Notification Platform" "Central internal service that receives normalized notification requests, applies policy, and delivers them through email, ServiceNow, and future Teams channels." {
            api = container "Notification API" "Single internal entry point used by all producer systems. Validates requests, authenticates callers, normalizes payloads, creates notification IDs, and accepts attachment uploads or references." "AWS Lambda/.NET 9 minimal API behind Amazon API Gateway" {
                requestController = component "Request Controller" "Receives HTTP requests and maps them to the internal notification command." "ASP.NET Core endpoint"
                callerAuth = component "Caller Authentication/Authorization" "Validates the internal caller identity and applies per-caller policy." "JWT/API key/mTLS policy"
                schemaValidator = component "Schema & Channel Validator" "Validates required fields, channel-specific payload rules, attachment metadata, and request size limits." "Validation component"
                normalizer = component "Notification Normalizer" "Creates the canonical notification model and generates the platform notification ID." "Application service"
                attachmentIngress = component "Attachment Ingress" "Stores uploaded files or resolves attachment references for later delivery." "S3 integration"
                dedupe = component "Idempotency & Audit Recorder" "Checks for duplicate requests and creates the initial audit record/state." "DynamoDB integration"
                policyLookup = component "Template & Policy Resolver" "Loads routing policy, environment suppression rules, templates, and recipient mappings." "Config integration"
                publishGateway = component "Orchestration Publisher" "Publishes validated notification commands to the routing/orchestration layer." "Step Functions/EventBridge/SQS integration"
            }
            orchestrator = container "Routing & Orchestration Engine" "Applies policy and routing rules, selects channels, performs idempotency checks, and coordinates delivery workflows." "AWS Lambda + AWS Step Functions"
            emailWorker = container "Email Delivery Worker" "Builds outbound email payloads, resolves templates and recipients, uploads large attachments when needed, and sends email through Microsoft Graph." "AWS Lambda"
            snowWorker = container "ServiceNow Delivery Worker" "Transforms normalized requests into approved ServiceNow incident/task payloads and submits them via REST APIs." "AWS Lambda"
            teamsWorker = container "Teams Delivery Worker" "Future adapter that will post messages to Microsoft Teams through Microsoft Graph." "AWS Lambda"
            auditStore = container "Audit & Status Store" "Stores request metadata, notification IDs, per-channel status, provider response IDs, deduplication keys, and operational history." "Amazon DynamoDB"
            attachmentStore = container "Attachment Store" "Temporary storage for uploaded or generated files before email delivery." "Amazon S3"
            templateStore = container "Template & Policy Store" "Stores templates, channel routing policies, recipient rules, and environment-specific suppression or escalation settings." "Amazon DynamoDB / AWS AppConfig"
            secretStore = container "Secrets & Integration Configuration" "Stores Microsoft Graph, ServiceNow, and other outbound integration credentials or certificates." "AWS Secrets Manager"
            opsMonitoring = container "Observability & Alerting" "Collects logs, metrics, traces, and alarms for the platform and its delivery workers." "Amazon CloudWatch"

            api -> orchestrator "Publishes normalized notification requests for evaluation and delivery orchestration" "JSON/async"
            api -> auditStore "Creates notification record, idempotency state, and initial status" "DynamoDB API"
            api -> attachmentStore "Stores attachments or temporary attachment references" "S3 API"
            api -> templateStore "Reads validation rules, templates, and routing policies" "Config lookup"
            api -> secretStore "Reads integration configuration where required" "Secrets Manager API"
            api -> corpIdentity "Authenticates and authorizes internal callers" "OAuth2/JWT, mTLS, or API key"
            orchestrator -> templateStore "Reads routing rules, escalation policy, recipient mapping, and environment suppression rules" "Config lookup"
            orchestrator -> auditStore "Reads and updates notification state, idempotency, and workflow progress" "DynamoDB API"
            orchestrator -> emailWorker "Dispatches email delivery jobs" "Async invoke / queue"
            orchestrator -> snowWorker "Dispatches ServiceNow delivery jobs" "Async invoke / queue"
            orchestrator -> teamsWorker "Dispatches Teams delivery jobs" "Async invoke / queue"
            orchestrator -> opsMonitoring "Emits workflow and routing metrics" "Metrics/logs"
            emailWorker -> templateStore "Reads email template, branding, recipients, and channel policy" "Config lookup"
            emailWorker -> attachmentStore "Reads pending attachment objects" "S3 API"
            emailWorker -> secretStore "Reads Graph credentials/certificates" "Secrets Manager API"
            emailWorker -> entra "Requests OAuth token for Microsoft Graph" "OAuth 2.0 client credentials"
            emailWorker -> graph "Sends mail and uploads large attachments via Graph" "HTTPS/REST"
            emailWorker -> auditStore "Stores message status and provider IDs" "DynamoDB API"
            emailWorker -> opsMonitoring "Emits logs, metrics, and alarms" "Metrics/logs"
            snowWorker -> templateStore "Reads ServiceNow mapping rules and assignment policies" "Config lookup"
            snowWorker -> secretStore "Reads ServiceNow credentials or OAuth settings" "Secrets Manager API"
            snowWorker -> servicenow "Creates incidents or tasks" "HTTPS/REST"
            snowWorker -> auditStore "Stores ticket status, sys_id, and incident number" "DynamoDB API"
            snowWorker -> opsMonitoring "Emits logs, metrics, and alarms" "Metrics/logs"
            teamsWorker -> templateStore "Reads Teams channel mappings and templates" "Config lookup"
            teamsWorker -> secretStore "Reads Graph credentials/certificates" "Secrets Manager API"
            teamsWorker -> entra "Requests OAuth token for Microsoft Graph" "OAuth 2.0 client credentials"
            teamsWorker -> graph "Posts Teams messages through Microsoft Graph" "HTTPS/REST"
            teamsWorker -> auditStore "Stores Teams delivery status and provider IDs" "DynamoDB API"
            teamsWorker -> opsMonitoring "Emits logs, metrics, and alarms" "Metrics/logs"

            requestController -> callerAuth "Authenticates caller"
            requestController -> schemaValidator "Validates body and channel payload"
            schemaValidator -> normalizer "Passes canonical input"
            normalizer -> attachmentIngress "Registers attachments when present"
            normalizer -> policyLookup "Resolves policy and template references"
            normalizer -> dedupe "Checks idempotency and stores initial state"
            normalizer -> publishGateway "Publishes normalized notification"
            callerAuth -> corpIdentity "Validates caller identity"
            attachmentIngress -> attachmentStore "Stores file objects / references"
            dedupe -> auditStore "Creates notification record"
            policyLookup -> templateStore "Reads policy/templates"
            publishGateway -> orchestrator "Starts routing workflow"

            production = deploymentEnvironment "Production" {
                aws = deploymentNode "Amazon Web Services" "Company AWS account" "AWS" {
                    region = deploymentNode "Primary Region" "Primary AWS region for production" "AWS Region" {
                        apiGatewayNode = deploymentNode "Amazon API Gateway" "Managed ingress" "API Gateway" {
                            containerInstance api
                        }

                        lambdaNode = deploymentNode "AWS Lambda" "Serverless compute runtime" "Lambda" {
                            containerInstance orchestrator
                            containerInstance emailWorker
                            containerInstance snowWorker
                            containerInstance teamsWorker
                        }

                        workflowNode = deploymentNode "AWS Step Functions" "Workflow orchestration" "Step Functions" {
                            infrastructureNode "Routing Workflows"
                        }

                        queueNode = deploymentNode "Amazon SQS" "Channel delivery queues" "SQS" {
                            infrastructureNode "Email Queue"
                            infrastructureNode "ServiceNow Queue"
                            infrastructureNode "Teams Queue"
                            infrastructureNode "Dead Letter Queue"
                        }

                        dataNode = deploymentNode "Data Services" "Operational platform stores" "AWS Managed Services" {
                            containerInstance auditStore
                            containerInstance templateStore
                            containerInstance attachmentStore
                            containerInstance secretStore
                        }

                        observabilityNode = deploymentNode "Amazon CloudWatch" "Logs, metrics, alarms, traces" "CloudWatch" {
                            containerInstance opsMonitoring
                        }
                    }
                }

                m365 = deploymentNode "Microsoft 365" "Enterprise Microsoft cloud" "Microsoft 365" {
                    deploymentNode "Microsoft Entra ID" "OAuth identity platform" "Entra ID" {
                        infrastructureNode "Token Endpoint"
                    }
                    deploymentNode "Microsoft Graph" "Graph APIs" "Graph API" {
                        infrastructureNode "Mail API"
                        infrastructureNode "Teams API"
                    }
                    deploymentNode "Exchange Online" "Mailbox infrastructure" "Exchange Online" {
                        infrastructureNode "Shared Mailbox / Service Account"
                    }
                    deploymentNode "Microsoft Teams" "Collaboration runtime" "Teams" {
                        infrastructureNode "Teams Channel / Chat"
                    }
                }

                snow = deploymentNode "ServiceNow SaaS" "Enterprise ITSM platform" "ServiceNow" {
                    infrastructureNode "Incident / Task API"
                }
            }
        }

        requester -> producerSystems "Owns or configures"
        producerSystems -> notification.api "Submits notification requests with business data and optional attachment references" "HTTPS/JSON"
        supportTeam <- exch "Receives operational emails from"
        supportTeam <- servicenow "Works incidents created in"
        platformTeam -> notification.opsMonitoring "Monitors platform health, delivery metrics, retries, and failures"
        corpIdentity -> producerSystems "Issues identities/credentials to callers"
        graph -> exch "Delivers outbound email through"
        teams -> supportTeam "Displays future collaboration messages to"
    }

    views {
        systemContext notification "system-context" {
            include *
            autoLayout lr
            title "System Context - Internal Notification Platform"
        }

        container notification "containers" {
            include *
            autoLayout lr
            title "Container View - Internal Notification Platform"
        }

        component notification.api "api-components" {
            include *
            autoLayout lr
            title "Component View - Notification API"
        }

        dynamic notification "request-flow" {
            title "Dynamic View - Email + ServiceNow notification request"
            producerSystems -> notification.api "1. Submit notification request with business payload and optional attachment references"
            notification.api -> notification.auditStore "2. Create notification record and correlation ID"
            notification.api -> notification.attachmentStore "3. Store uploaded attachment or resolve attachment reference"
            notification.api -> notification.orchestrator "4. Publish normalized request"
            notification.orchestrator -> notification.templateStore "5. Load policy, routing, templates, and suppression rules"
            notification.orchestrator -> notification.emailWorker "6. Dispatch email delivery"
            notification.orchestrator -> notification.snowWorker "7. Dispatch ServiceNow delivery"
            notification.emailWorker -> entra "8. Obtain Graph access token"
            notification.emailWorker -> graph "9. Send email / upload large attachment"
            graph -> exch "10. Deliver message"
            notification.snowWorker -> servicenow "11. Create incident/task"
            notification.emailWorker -> notification.auditStore "12. Store provider message ID and status"
            notification.snowWorker -> notification.auditStore "13. Store ticket identifiers and status"
        }

        deployment notification notification.production "deployment" {
            include *
            autoLayout lr
            title "Deployment View - Production"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            relationship "Asynchronous" {
                style dashed
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
