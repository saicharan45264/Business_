# Giri Fruits — Complete Implementation Plan

Prepared: 21 November 2026  
Document status: Implementation blueprint; application development has not started.  
Initial delivery: React business software with a Node.js API and PostgreSQL.  
Future delivery: Flutter mobile application using the same API and database.

## 1. Business objective and confirmed requirements

Replace the daily paper records used to purchase fruit boxes from Vijayawada wholesalers, receive and manage stock in Eluru, sell boxes to retailers, send bills, and collect payments.

The system must connect stock and money movements. Entering a transaction once should update its related records automatically, while retaining a traceable history.

| Requirement | Confirmed decision |
| --- | --- |
| Trading unit | Whole boxes only, for both purchases and sales |
| Suppliers | Multiple wholesalers in Vijayawada |
| Customers | Retail shop owners in and around Eluru |
| Payments | Cash and UPI; payment can happen immediately or later |
| Credit | Unpaid bills, partial payments, and later collections are required |
| Daily usage | Approximately 20–30 sales bills |
| Initial language | English |
| Future editing | Centralised interface text, editable business settings, future translations |
| Initial frontend | React |
| Backend preference | Node.js or FastAPI |
| Database | PostgreSQL |
| Future mobile frontend | Flutter |
| Bill delivery | Printable bills and PDFs that can be shared with retailers |

Planning assumptions: one business and one initial stock location; owner and staff accounts; INR currency; Asia/Kolkata business timezone. Keep business and location identifiers in the model, but confirm actual user count and devices during discovery.

Initial software means a desktop-friendly browser application, with responsive layouts and an installable shortcut/PWA shell. Confirm whether a Windows installer is essential in the discovery stage. A React desktop wrapper can be added if required; packaging alone does not provide offline operation.

The first release replaces operational purchase, sales, stock, collections, and cash books. Statutory filings and final financial statements remain an accountant-reviewed process using the system's ledger and exports.

## 2. Proposed technology decisions

### 2.1 Recommended stack

| Layer | Proposed choice | Reason for this project |
| --- | --- | --- |
| Business frontend | React + TypeScript + Vite | Focused business interface, separate from the reusable backend |
| Navigation | React Router | Explicit routes for billing, stock, collections, reports, and settings |
| Server state | TanStack Query | Fetching, caching, invalidation, and visible request states |
| Forms | React Hook Form + Zod | Predictable form handling and user-friendly validation |
| Components | MUI with a small application theme | Consistent accessible forms, dialogs, tables, and responsive layouts |
| Backend | Node.js + TypeScript + NestJS | Structured business modules and one language across the initial application |
| API | Versioned REST/JSON + OpenAPI | A documented contract usable by React and Flutter |
| Database | PostgreSQL | Relational constraints, exact decimal values, and transactions |
| Database access | Prisma ORM + reviewed SQL migrations | Model access and migration history, with SQL for locks and specialised constraints |
| Money calculations | Decimal arithmetic library, matched to database rounding rules | Avoid binary floating-point errors in prices and totals |
| Bill rendering | Server-side HTML/CSS templates rendered to PDF using Playwright | Consistent saved bill documents and print layouts |
| Attachments | Private S3-compatible object storage | Supplier photos, issued PDFs, exports, and controlled downloads |
| Background work | PostgreSQL-backed outbox/job tables + worker from the same codebase | Durable PDF generation and exports at this volume |
| Local development | pnpm workspace + Docker Compose for PostgreSQL and local object storage | Repeatable development setup |
| Delivery | Containerised API/worker, managed PostgreSQL, HTTPS reverse proxy | Clear deployment and recovery process |
| Future mobile | Flutter + a Dart API client derived from the OpenAPI contract | Reuse backend behaviour and records |

React's documentation describes building with Vite, and NestJS documents modular server applications and OpenAPI integration. These support the proposed approach; the particular combination above is a project design choice. Sources: [React build tooling](https://react.dev/learn/build-a-react-app-from-scratch), [NestJS](https://docs.nestjs.com/), [NestJS OpenAPI](https://docs.nestjs.com/openapi/introduction).

Select compatible, supported releases when scaffolding. Pin exact dependency versions and commit lockfiles. Do not base the project on whichever unpinned version happens to be available on each developer's machine.

### 2.2 Why Node.js rather than FastAPI for the baseline

Recommend NestJS because the initial frontend is React/TypeScript and the business rules benefit from explicit modules, services, validation, and permissions. This reduces language switching for the initial development and maintenance.

FastAPI is a valid replacement if the implementation team is stronger in Python. In that case, use FastAPI, Pydantic, SQLAlchemy, Alembic, and PostgreSQL, while retaining the same REST contract, transactional rules, schema concepts, and React/Flutter clients. FastAPI documents OpenAPI and JSON Schema support. [FastAPI features](https://fastapi.tiangolo.com/features/)

Choose one backend before implementation. Flutter does not require a Python backend or a backend rewrite.

### 2.3 Application structure

Use a modular monolith: one backend application with clear business modules, one PostgreSQL database, and one worker built from the same repository.

~~~text
React business software ── HTTPS /api/v1 ──┐
                                         ├── NestJS business modules ── PostgreSQL
Flutter mobile app later ─ HTTPS /api/v1 ──┘                │
                                                          ├── Private document storage
                                                          └── Durable jobs → PDF/export worker
~~~

Stock, credit, permissions, costing, and posting rules live on the server. Clients collect input and display results. Neither client connects directly to PostgreSQL.

## 3. Delivery scope

### 3.1 First production release

- Business settings, user accounts, permissions, and audit history.
- Fruit/variety/grade/packing catalogue, with one stock unit: BOX.
- Supplier and retailer records.
- Opening stock, retailer dues, supplier dues, advances, cash, and bank balances.
- Goods receipts, supplier bills, shortages, purchase costs, and supplier payments.
- Batch stock, box movements, physical stock counts, and damage.
- Retailer sales, credit bills, cash/UPI receipts, allocations, and advances.
- Retailer and supplier returns, financial credits, and refunds.
- Printable bills, saved PDF bills, receipts, and account statements.
- Expenses, cash/bank transfers, daily reconciliation, and owner withdrawals.
- Stock, receivable, payable, margin, expense, and cash reports.
- English interface, editable business/bill settings, and translation structure.
- Backups, restore drill, export, production monitoring, and staff training.

### 3.2 Later releases

| Enhancement | Trigger / dependency |
| --- | --- |
| Flutter Android app | Stable API and a completed browser pilot |
| iOS app | Confirm devices, distribution needs, and platform testing |
| Automatic WhatsApp bills/reminders | Official platform setup, recipient permission, templates, and provider pricing |
| Telugu interface | Approved translations; shared language keys and font/layout checks |
| Retailer self-service access | Explicit permission model for a retailer to see only their records |
| Multiple warehouses/branches | Confirm transfers, stock ownership, and reporting requirements |
| Returnable crate/deposit tracking | Confirm whether containers are actually exchanged |
| Accounting integration | Agree on target accounting software and mapping |
| Windows desktop installer | Confirm installation, updates, signing, and printer needs |
| Offline final billing | Required before retiring books if connectivity testing shows outages cannot be covered |

Loose units, fractional boxes, and weight conversion are outside the confirmed trading model. Packing descriptions can distinguish box types without introducing kilogram-based stock.

## 4. Users, permissions, and setup

| Capability | Owner | Billing staff | Stock staff | Accountant/read-only |
| --- | --- | --- | --- | --- |
| Create sales and record collections | Yes | Yes, if granted | No by default | View |
| Receive stock | Yes | Optional | Yes | View |
| See purchase costs and margins | Yes | No by default | Optional | Yes |
| Record supplier payments and expenses | Yes | Optional | No by default | View |
| Change stock or issue refunds | Yes | Restricted permission | Request/count only | View |
| Change users, opening balances, or settings | Yes | No | No | No |
| Export records | Yes | Restricted | Restricted | If granted |
| View audit history and close periods | Yes | No | No | View |

Enforce permissions in every backend route and service, including PDFs, exports, and reports. Hiding a frontend button is insufficient.

Create the first owner through a controlled setup command, then disable bootstrap access. Each person gets a separate account. Deactivate users and catalogue entries instead of deleting referenced records.

Discovery setup data: business details, retailer and supplier lists, product/packing names, sale prices, staff permissions, printer/device details, opening balances, business registration details, and sample supplier/customer bills.

## 5. Catalogue and box inventory rules

Each sellable product is a distinct SKU, such as Apple / Grade A / Large box. Store SKU code, display name, fruit, variety, grade, packing description, active status, and optional default purchase/sale rates.

Box quantities are positive integers on normal document lines. Reject fractions at both API and database boundaries. Direction is represented by the movement type, not by a negative sales quantity.

A batch identifies an arrival, supplier, SKU, location, and receipt date. Different purchase rates remain separate batches. If delivery condition suggests urgency, staff can select the batch physically supplied; the system otherwise suggests the oldest eligible arrival.

Use saleable and damaged/quarantined stock states. A damaged box remains traceable but cannot be sold as saleable stock without an authorised reclassification.

Stock availability is derived from posted movements:

~~~text
Saleable closing boxes =
  opening saleable boxes
  + saleable goods received
  + saleable retailer returns
  - boxes sold
  - boxes returned to suppliers
  - boxes moved to damaged stock
  +/- approved count corrections
~~~

A damaged reclassification moves boxes between states; disposal removes damaged boxes. These are separate events so damage is not deducted twice.

Draft bills do not deduct or reserve stock in version 1. Recheck availability when issuing. Use transactional locking to prevent simultaneous sales from overselling a batch.

## 6. Purchase, receipt, and supplier workflows

### 6.1 Receive boxes

1. Choose supplier and arrival date.
2. Enter SKU, expected/billed boxes, actual received boxes, condition, and estimated rate.
3. Attach the supplier bill or arrival photo if available.
4. Enter direct freight/loading costs or mark them pending.
5. Post the goods receipt; stock increases exactly once.
6. Create or match the supplier bill, either immediately or later.

Provide a single purchase screen that can save a receipt and supplier bill together, while keeping them as separate linked records. Posting the bill must not receive stock a second time.

Supplier bills may match more than one receipt, and receipts may be matched in parts. Prevent cumulative matched quantities from exceeding the relevant quantities without an explicit discrepancy workflow.

### 6.2 Shortage, damage, and disputed bills

Store billed quantity, received quantity, damaged quantity, billed amount, and a discrepancy note separately.

Example: supplier bills 50 boxes, but 48 arrive. Receive 48 boxes. Record the 2-box claim and the supplier's response. Do not silently lower the supplier bill or create a financial credit merely because a claim was raised.

Use a discrepancy/claim record with open, accepted, rejected, and settled states. An accepted settlement creates the appropriate linked supplier credit, replacement receipt, or adjustment. Prevent one settlement from being applied twice.

The receipt/bill matching service must route a disputed quantity/value variance to a reviewed discrepancy account or approved cost/loss treatment, rather than incorrectly spreading it across the received boxes. Accountant approval of this policy is a discovery deliverable.

### 6.3 Landed cost

Landed batch cost includes purchase cost and approved direct freight/loading costs, net of applicable purchase credits.

Allocate shared arrival costs by box count as the initial default, with an owner-editable per-line allocation before posting. Show the method and allocated amounts. Require the allocation total to equal the original charge.

Capitalised transport costs increase stock cost; do not also charge the same amount as an operating expense. Track who is owed the charge separately from which batch receives its cost.

Allow provisional costs while awaiting a bill. When final costs change, post a cost adjustment that splits the difference between stock still held and the cost of boxes already sold. Preserve the adjustment trail and identify reports containing provisional costs.

### 6.4 Supplier payments

Record payments independently of purchases. Support cash and UPI, split tenders, partial settlement, settlement of several bills, supplier advances, and unused credit balances.

Apply payments to selected open supplier bills, with oldest-first suggestions. Record references and print/export a settlement statement. Reversals must undo both allocations and accounting effects.

## 7. Sales, billing, and sharing

### 7.1 Billing workflow

1. Select retailer; display outstanding balance and optional credit warning.
2. Add SKUs; display available boxes and suggested batch.
3. Enter integer box quantities and sale rates.
4. Apply permitted discounts or charges with reasons.
5. Optionally add confirmed cash/UPI payment.
6. Preview and issue the bill.
7. Print, download, or share the saved document.

Defaults should speed entry, but issued lines retain the actual agreed price. Require permission or a warning policy for sales below landed cost and sales above a configured credit limit. Allow an owner override with a reason.

### 7.2 Bill content

Include business identity/contact details, document type, unique financial-year bill number, date, retailer identity, line descriptions, boxes, rates, discounts, applicable tax/charges, rounding, total, payment received, balance on this bill, and account outstanding.

Show previous outstanding separately from new sales. State that account outstanding is a snapshot as of issue time. Payments collected later appear in receipts and current statements; do not silently rewrite an old issued PDF.

~~~text
GIRI FRUITS
Bill: GF/2026-27/000123
Retailer: Sri Lakshmi Fruit Shop

Apples       5 boxes × INR 1,400.00 = INR 7,000.00
Oranges      3 boxes × INR   800.00 = INR 2,400.00

Today's bill                         INR 9,400.00
Payment received                     INR 2,000.00
Unpaid on this bill                  INR 7,400.00
Previous account outstanding         INR 3,000.00
Account outstanding after posting   INR 10,400.00
~~~

Use the applicable legal document type. CBIC guidance distinguishes commercial invoices and bills of supply for exempt supplies according to registration circumstances. Confirm registration, item classification, required fields, and any tax/e-invoicing obligations with the business's accountant before production; do not assume every fruit product has identical treatment. [CBIC sectoral FAQs](https://cbic-gst.gov.in/sectoral-faq.html)

### 7.3 Document lifecycle

Drafts are editable and have no financial number or posting effect. Issuing assigns the number and atomically creates stock and accounting entries. Payment status is derived separately as unpaid, partly paid, paid, or credit.

Issued documents are immutable. Corrections use linked cancellations, returns, credit/debit adjustments, and replacement documents where appropriate. Retain number, reason, actor, time, original PDF, and reversal references.

Use one numbered series per business/document type/financial year. Allocate a number under a database lock when posting. Retain voided numbers, never reuse them, and explain any gaps in the audit history.

### 7.4 PDF and WhatsApp delivery

Generate PDFs from immutable snapshots, with a template version and checksum. Start with an A4 template; validate a thermal format against the actual printer before adding it as an accepted output.

On supported devices, open the system share sheet with the PDF. Otherwise download and attach it manually in WhatsApp. A text message or protected bill link is another explicit option.

Manual sharing cannot reliably prove that a message was delivered or read. Record the share attempt, not a fabricated delivery status. Automatic delivery/read statuses are a later provider integration.

Use private documents and revocable, expiring, unguessable sharing tokens for bill links. The link must expose only the intended document, not the retailer ledger. Retailers do not need an application account to receive a PDF.

Automatic WhatsApp sending is a later integration. WhatsApp requires recipient permission and approved templates for platform-initiated conversations, with restrictions outside the customer-service window. Recheck onboarding rules and pricing when implementing. [WhatsApp messaging policy](https://whatsappbusiness.com/policy/)

PDF generation runs after financial posting through a durable job. A rendering or sharing failure must not undo, duplicate, or recreate the bill. Show “Bill saved; PDF pending” and allow regeneration from the same snapshot.

## 8. Collections, credit, returns, and refunds

### 8.1 Retailer receipts

Support collections on the sale date or any later date. A receipt has the retailer, business date, received timestamp, amount, cash/UPI components, receiving account, collector, optional UPI reference, and notes.

One receipt can settle several bills. One bill can have several receipts. Suggest oldest-due-first allocation but let authorised staff choose. Allocate opening dues using the same mechanism.

Store any unallocated amount as customer credit/advance. Never convert an overpayment into additional sales. A split-tender receipt has one receipt number and separate cash/UPI components.

Staff must confirm receipt of UPI funds against the actual transaction. A displayed QR code, screenshot alone, or a Share button action must not automatically settle a bill. Bank reconciliation can flag unverified or missing matches.

### 8.2 Ledger rules

Calculate balances from posted financial records and allocation events. Do not maintain an independently editable “current due” as the source of truth.

Distinguish gross unpaid invoices, customer advances/unapplied credits, net account position, and overdue invoices. Show customer credit clearly rather than presenting an unexplained negative due.

Age overdue balances using their due dates. Opening items need dates where available; otherwise mark their ageing as unknown, rather than inventing exact ages.

### 8.3 Returns and refunds

Link a sales return to the original sale line and batch allocation. Enforce cumulative return quantity limits and value limits. Record credit-only adjustments separately from physical returns.

Saleable returns re-enter saleable stock at the original cost basis. Damaged returns enter quarantine/damaged stock, with the appropriate impairment/loss entry. A financial credit does not by itself prove stock was returned.

If the original bill is unpaid, the credit reduces the open amount. If already settled, create customer credit or record an authorised refund. Prevent a return from both reducing a due and refunding the same amount twice.

Supplier returns similarly separate the physical box movement from an accepted financial supplier credit. All refunds and reversals retain their original links.

## 9. Accounting, expenses, and reports

Use an internal double-entry posting engine with simple business-facing screens. Staff should not need to enter journal lines for ordinary transactions.

Core accounts: cash, UPI-linked bank accounts, receivables, payables, inventory, goods received not invoiced (GRNI), sales, sales returns, cost of goods sold, damage loss, operating expenses, customer advances, supplier advances, discrepancy clearing, opening balances, and owner capital/drawings.

Illustrative posting rules, excluding tax detail:

| Event | Debit | Credit |
| --- | --- | --- |
| Goods receipt at provisional cost | Inventory | GRNI |
| Supplier invoice matched at same value | GRNI | Supplier payable |
| Credit sale | Retailer receivable | Sales |
| Cost of boxes sold | Cost of goods sold | Inventory |
| Receipt against dues | Cash / bank | Retailer receivable |
| Unallocated customer advance | Cash / bank | Customer advances |
| Apply customer advance | Customer advances | Retailer receivable |
| Supplier payment against dues | Supplier payable | Cash / bank |
| Supplier advance | Supplier advances | Cash / bank |
| Apply supplier advance | Supplier payable | Supplier advances |
| Final inventory damage write-down | Damage loss | Inventory valuation |
| Operating expense paid | Expense | Cash / bank |
| Cash deposited into bank | Bank | Cash |
| Owner withdrawal | Owner drawings | Cash / bank |

Extend the posting matrix for returns, refunds, discrepancies, tax, landed costs, provisional-cost differences, opening records, and reversals before implementing those flows. Require every posted journal to balance. GRNI and discrepancy accounts must have reconciliation reports.

Return documents use the original cost basis, subject to any attributable later cost adjustment. A physical move into quarantine does not automatically create a second financial write-down.

Support unpaid expenses as payables and paid expenses through cash/bank accounts. Stock freight entered through purchases must not also be entered as an unrelated expense.

Reports:

| Report | Required detail |
| --- | --- |
| Daily dashboard | Sales, collections by method, returns, outstanding balances, stock alerts |
| Sales register | Date, bill, retailer, SKU, boxes, rate, net sales, payment status |
| Retailer statement | Opening position, bills, credits, receipts, refunds, running balance |
| Outstanding/ageing | Unpaid documents, due dates, age buckets, unapplied advances |
| Supplier statement | Bills, credits, payments, advances, running balance |
| Stock register | SKU, batch, location, stock state, receipts, sales, returns, adjustments |
| Inventory valuation | Remaining boxes, allocated costs, provisional-cost flags |
| Arrival/batch margin | Net sales, sold cost, damage and cost adjustments |
| Expense report | Category, account, date, amount, supporting document |
| Daily cash close | Opening cash, receipts, cash outflows, expected/actual cash, variance |
| Bank/UPI reconciliation | Recorded receipts/payments versus external entries |
| Reconciliation controls | Receivables/payables versus ledger, inventory versus ledger, GRNI |

Gross profit = net sales excluding applicable tax minus cost of boxes sold. Operating profit estimate additionally deducts recognised losses and operating expenses. Unsold purchases remain inventory; collections are not sales.

Expose business-date filters and “as of” balances. Backdated corrections must respect closed periods and cannot silently change a signed-off day.

## 10. PostgreSQL data model

This is the logical schema. Implement actual migrations, indexes, constraints, and reviewed posting rules during development.

| Area | Tables and important fields |
| --- | --- |
| Organisation | businesses; locations; business_settings; financial_periods |
| Identity | users; roles; user_roles; sessions; permission_grants |
| Catalogue | fruits; varieties; grades; packing_types; products/SKUs |
| Parties | parties; party_roles; party_contacts; credit_terms |
| Receipts | goods_receipts; goods_receipt_lines; stock_batches |
| Supplier bills | purchase_invoices; purchase_invoice_lines; receipt_invoice_matches |
| Purchase costs | landed_costs; landed_cost_allocations; batch_cost_adjustments |
| Discrepancies | supplier_claims; claim_settlements |
| Stock | stock_movements; batch_balances; stock_counts; stock_count_lines |
| Sales | sales_invoices; sales_invoice_lines; sale_batch_allocations |
| Money | money_accounts; payments; payment_tenders; open_items; allocation_events |
| Returns | sales_returns; sales_return_lines; purchase_returns; purchase_return_lines |
| Adjustments | credit_debit_notes; note_lines; refund_links |
| Expenses | expenses; expense_categories; expense_lines |
| Ledger | ledger_accounts; journal_entries; journal_lines |
| Migration | opening_balance_batches; opening_items; import_runs; import_row_errors |
| Documents | document_snapshots; document_files; share_tokens; delivery_attempts |
| Reliability | document_sequences; idempotency_requests; outbox_jobs; audit_events |
| Bank close | bank_statement_imports; bank_statement_rows; reconciliation_matches; daily_closes |

Important relationships and constraints:

- Every business record belongs to a business; every stock event identifies a location, SKU, batch, and state.
- A party can have retailer and supplier roles, but report its receivable and payable positions separately unless an explicit offset is approved.
- Sales invoice lines may consume several batches. Store the quantity and cost allocation for each.
- Receipt/invoice matching tracks quantities and amounts, including partial matches.
- Open items represent collectible/payable documents, credits, and opening dues. Allocation events link settlements to specific open items.
- Allocation reversals are appended events; do not erase the original allocation history.
- Payments describe direction, party, total, state, and business date. Tenders describe the actual cash/bank accounts and amounts.
- A journal references its source event; a unique source-event posting key prevents duplicate accounting.
- A stock movement has a unique source-event key, so retrying a receipt cannot receive stock twice.
- Batch balances are a transactionally maintained projection for locking and fast reads; the append-only movement history must rebuild them.
- Credit notes that only change value must not create stock movements.
- Foreign keys prevent orphan lines, allocations, and attachments. Add business-boundary validation to all references.
- Index business/date, party/date, document number, product/location/state, batch/date, unpaid items, and pending job lookup.

Data conventions:

- UUID primary identifiers; human-readable bill numbers are separate.
- Integer box counts, with positive document-line checks and controlled movement directions.
- NUMERIC(18,2) for posted monetary amounts; higher precision such as NUMERIC(20,6) for allocated per-box costs.
- API money values are decimal strings, for example "1400.00". Use decimal arithmetic end to end.
- Round posted amounts consistently to paise; distribute allocation remainders deterministically so totals reconcile.
- UTC TIMESTAMPTZ for events; a separate DATE for the business date; Asia/Kolkata for business display.
- Store currency explicitly as INR and fiscal-year boundaries as configuration.
- Master-data deactivation rather than deletion after use.
- Optimistic version numbers on editable drafts and settings.
- Snapshot descriptions, addresses, rates, tax treatment, and template version on issued documents.

PostgreSQL documents exact NUMERIC values for monetary calculations and database transactions for all-or-nothing writes. These are the basis for the chosen storage and posting approach. Sources: [Numeric types](https://www.postgresql.org/docs/current/datatype-numeric.html), [Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html).

## 11. API contract and financial consistency

### 11.1 Endpoint groups

All routes begin with /api/v1. The table shows representative groups; publish the exact contract through OpenAPI.

| Group | Representative operations |
| --- | --- |
| Authentication | POST /auth/login; POST /auth/logout; GET /auth/me |
| Masters | /products; /retailers; /suppliers; /locations; /settings |
| Purchases | /goods-receipts; /purchase-invoices; /supplier-claims; /landed-costs |
| Stock | GET /stock; GET /stock/batches; POST /stock-counts; POST /stock-adjustments |
| Sales | /sales-invoices; POST /sales-invoices/{id}/issue; POST /sales-invoices/{id}/cancel |
| Collections | /receipts; POST /receipts/{id}/post; POST /receipts/{id}/reverse |
| Supplier payments | /supplier-payments; posting, allocation, and reversal actions |
| Returns | /sales-returns; /purchase-returns; /credit-notes; /refunds |
| Cashbook | /expenses; /account-transfers; /daily-closes; /bank-reconciliations |
| Party statements | GET /retailers/{id}/statement; GET /suppliers/{id}/statement |
| Documents | GET /documents/{id}/pdf; POST /documents/{id}/share-links |
| Reports | /reports/sales; /reports/outstanding; /reports/stock; /reports/margins |
| Administration | /users; /roles; /audit-events; /imports; /exports |

Contracts include validation rules, decimal-string money, integer boxes, timestamps, explicit status enums, pagination, filters, stable error codes, and sample payloads. Maintain an OpenAPI contract test and generated TypeScript client; generate and compile a small Dart client before the browser release.

### 11.2 Issuing a sales bill

1. Authenticate and authorise; validate business, party, draft version, and inputs.
2. Claim an Idempotency-Key scoped to business and operation. Compare the request hash.
3. Start one database transaction and lock the draft, relevant batch balances, and required party/allocation records in a consistent order.
4. Recheck stock, credit rules, price permissions, tax configuration, and business-date lock.
5. Allocate batches; calculate amounts and costs on the server.
6. Allocate the bill number under lock.
7. Write immutable invoice data, stock movements, balanced journals, open items, any immediate confirmed receipt and allocations, document snapshot, audit event, and outbox job.
8. Persist the idempotent result in the same transaction and commit.
9. Return the issued document identifier; the worker generates its PDF independently.

Treat transaction conflicts/deadlocks as retryable with bounded retries and the same idempotency key. No network calls or PDF rendering inside the transaction. PostgreSQL and the ORM transaction facilities provide the primitives; correctness still requires the application rules and constraints. [Prisma transactions](https://www.prisma.io/docs/orm/prisma-client/queries/transactions)

### 11.3 Other consistency rules

- Retry after a lost response returns the original result; the same key with different input is rejected.
- Lock allocation targets so two collectors cannot over-allocate the same bill or receipt.
- Enforce receipt allocations plus unallocated credit equal the confirmed received amount.
- Enforce tender amounts equal the payment total.
- Enforce invoice quantity equals its batch-allocation total.
- Reject unavailable stock and future/unpermitted backdated postings.
- Enforce balanced journals at posting, with database-backed controls; run reconciliation checks as an additional safeguard.
- Use cancellation/reversal services that restore every affected stock, open-item, tender, and journal effect exactly once.
- If goods have actually left or returned, use the corresponding business return rather than treating cancellation as proof of a physical movement.
- Use optimistic versions for simultaneous draft edits; do not overwrite another person's work silently.
- Never accept client-calculated outstanding amounts, inventory cost, or posting totals as authoritative.

## 12. Frontend screens and English editing

### 12.1 Screen map

| Screen | Main interactions |
| --- | --- |
| Dashboard | Daily totals, balances, stock warnings, pending documents |
| New Sale | Retailer search, SKU entry, boxes, prices, tenders, issue/share |
| Sales register / detail | Search, document history, PDF, receipts, returns |
| Collections | Retailer selection, open bills, allocations, cash/UPI, receipt |
| Purchases / arrivals | Supplier, boxes, receipt/bill matching, freight, discrepancy |
| Supplier payments | Open bills, settlement, advances, statement |
| Stock / batch detail | Available and damaged boxes, movement trail, provisional costs |
| Counts / damage / returns | Controlled quantity actions and reasons |
| Retailer / supplier detail | Contact details, transactions, dues, advances, statements |
| Cashbook / expenses | Money movement, category, proof, daily close |
| Reports | Filters, totals, reconciliation, PDF/CSV export |
| Settings / users | Business identity, bill wording, numbering, roles, translations |

Prioritise keyboard-friendly billing, readable totals, searchable selectors, clear pending/error states, and confirmation for consequential posting actions. Keep unsaved drafts separate from issued bills.

### 12.2 Editable text

- Keep interface labels in a central English translation file, using stable keys such as sales.newBill and payments.received.
- Separate labels from API field names, database identifiers, and business rules.
- Provide settings for business identity, payment details, footer wording, and product display names.
- Version the bill template and snapshot settings on issued documents.
- Plan a second translation file for Telugu and a language selector.
- Keep audit/event codes stable; translate displayed messages at the client.
- Document how to edit English wording and redeploy.

Editing translation files requires a build/deployment. If no-code editing of all labels is wanted later, add a versioned database override layer with a validated preview and export/import. Ordinary business settings should already be editable from the owner interface.

## 13. Flutter mobile roadmap

Flutter is a later client of the same backend. Its networking documentation covers HTTP access across supported platforms. [Flutter networking](https://docs.flutter.dev/data-and-backend/networking)

Prepare now:

- Publish and test the REST/OpenAPI contract.
- Keep business logic and posting on the server.
- Use stable IDs, decimal strings, explicit statuses, and cursor/page pagination.
- Protect APIs with the same permission and business-boundary checks for every client.
- Separate document generation from browser-specific code.
- Test API changes for backwards compatibility.

Mobile implementation steps:

1. Create a Flutter application with feature modules for login, dashboard, retailers, sales, collections, stock, and documents.
2. Generate or implement the Dart client from the reviewed contract; use a consistent error and retry layer.
3. Use a chosen Flutter state-management approach, such as Riverpod, consistently.
4. Add native authentication through revocable short-lived access tokens and rotating refresh tokens; store credentials in platform secure storage.
5. Build the retailer statement, bill viewing/sharing, and collection workflows first.
6. Add sales and stock screens with the same server validations.
7. Test device sharing, PDF downloads, camera attachments, session revocation, and weak-network retries.
8. Pilot Android on actual staff phones, then prepare distribution and ongoing update ownership.

Existing React UI code is not reused as Flutter widgets; API contracts, records, and server rules are reused. An owner/staff app does not automatically grant retailer logins.

Planning allowance after a stable backend: approximately 4–6 developer weeks for an online Android owner/staff app with core workflows. Full desktop feature parity, iOS, offline operation, and store review add separate effort.

## 14. Connectivity and desktop operation

Baseline: online posting with persisted server drafts, clear network status, safe retries, and download/print support. PWA installation is a convenience, not a promise of offline accounting.

During discovery, test the actual counter connection and a backup connection. Record what the business will do during internet or power failure.

Choose the operating model before finalising the build:

| Model | Benefit | Consequence |
| --- | --- | --- |
| Hosted API/database with reliable primary and backup internet | Simplest shared records and future mobile access | Final posting requires connectivity |
| Hosted system plus controlled offline counter billing | Counter can continue temporarily | Requires local durable storage, number allocation, reconciliation, and conflict design |
| Local server with remote synchronisation | Local network operation | Adds power, local backups, remote access, and synchronisation ownership |

If offline final billing is essential, add a dedicated work package before retiring books:

- Restrict offline issuing initially to one enrolled counter device and a defined cached stock allowance.
- Reserve stock allowances on the server before disconnection so online users cannot sell the same boxes.
- Allocate document number ranges that comply with the approved numbering policy.
- Persist local documents and payment events durably, encrypt sensitive local data, and use immutable event identifiers.
- Synchronise idempotently; expose pending/conflict states and a supervised resolution screen.
- Prevent different devices from allocating the same dues while disconnected.
- Reconcile device events with server stock, ledger, numbering, and receipts before closing the day.
- Test browser/device restart, storage limits, device loss, prolonged outage, and duplicate upload.

Allow an additional 2–4 weeks as a preliminary estimate for a constrained offline counter design; confirm through a prototype. Do not promise unrestricted multi-device offline stock and credit in that estimate.

An Electron or similar desktop wrapper can reuse the React client if an installer or specialised printer access is required. Its signing, update mechanism, storage, and security need their own acceptance checks.

## 15. Security, jobs, and operational reliability

### 15.1 Access and data protection

- HTTPS throughout; private PostgreSQL networking.
- Password hashes using a maintained password-hashing implementation; rate-limited login and secure owner reset.
- Browser sessions using Secure, HttpOnly cookies, appropriate SameSite policy, CSRF protection, expiry, and server-side revocation.
- Same-origin reverse proxy for React and API where possible; explicitly restricted CORS when needed.
- Later native tokens have revocation and rotation; do not store long-lived credentials in plain client storage.
- Validate business ownership for every referenced party, document, account, batch, and file.
- Keep costs/margins and export permissions restricted by role.
- Validate attachment size/type, generate safe storage keys, and serve active content only as downloads.
- Secrets stay in deployment secret storage; frontend configuration contains no private database or storage credentials.
- Redact passwords, tokens, private sharing links, and sensitive payloads from logs.
- Retain source-linked audit history with actor, action, business date, event time, and reason.
- Configure data retention and export access with the owner/accountant.

### 15.2 Background jobs

Use durable outbox jobs created in the same transaction as their source event. Workers claim jobs under database locks, retry with backoff, and surface permanently failed jobs for owner/support review.

Make PDF/export tasks idempotent. Store document checksum and version. Keep job status separate from financial status. Future messaging jobs use the same principle and must not resend indefinitely after ambiguous provider results.

### 15.3 Hosting and backups

Environments: local development, staging with sample data, and production. Production migrations are reviewed and backed up; use forward-compatible changes and preserve rollback compatibility with the previous application release.

Recommended initial deployment: one API service, one worker process, managed PostgreSQL, private object storage, HTTPS, automated deployments, structured logs, health checks, and error/backup alerts.

Proposed recovery targets to verify against the selected hosting plan:

- Database recovery point objective: at most 15 minutes using verified point-in-time recovery.
- Recovery time objective: restore essential operations within 4 hours.
- Daily database snapshots retained for 30 days, plus provider retention appropriate to business/accountant requirements.
- Versioned/recoverable document storage, with backups protected from ordinary application deletion.
- At least one independent backup copy or export under owner-controlled access.
- Restore database and documents together in staging before launch and at least quarterly.

These are requirements to validate, not guarantees from an unnamed hosting provider. If the provider cannot meet them, document the actual recovery window before launch.

Monitor API errors, posting failures, pending jobs, backup failures, storage growth, slow queries, and reconciliation mismatches. Assign a named person to respond.

## 16. Repository and implementation organisation

Suggested structure:

~~~text
giri-fruits/
  apps/
    web/                    React business software
    api/                    NestJS modules and worker entrypoint
    mobile/                 Flutter client when its phase starts
  packages/
    api-contract/           Reviewed OpenAPI definition and examples
    api-client-ts/          Generated TypeScript client
    config/                 Shared TypeScript/build configuration
  database/
    migrations/             Ordered reviewed schema/data changes
    seeds/                  Development fixtures and initial configuration
  templates/
    bills/                  Versioned printable templates
    statements/
  docs/
    setup.md
    business-rules.md
    posting-matrix.md
    deployment.md
    backup-restore.md
    user-guide.md
  tests/
    integration/
    e2e/
    reconciliation/
  infra/
    compose.yaml
    containers/
    deployment/
~~~

Backend modules: auth, users, organisation, catalogue, parties, purchases, inventory, sales, payments, returns, accounting, expenses, reports, documents, settings, audit, imports, and jobs.

Frontend feature modules mirror the workflows. Avoid exposing ORM/database models as the public API. Keep DTOs and generated clients tied to OpenAPI.

CI should run formatting/linting, type checks, migration checks, API contract checks, relevant tests, production builds, and container builds. Test migrations against a disposable PostgreSQL database.

## 17. Development phases and reviewable milestones

Estimate for the detailed production scope: approximately 40–50 developer days, usually 8–10 calendar weeks for one experienced full-stack developer with prompt business feedback and focused QA. Allow another two weeks of contingency for legacy-data cleanup, printer issues, or extended pilot corrections.

The earlier 6–8 week estimate describes a lean working version. This fuller plan includes posting/reconciliation controls, receipt matching, recovery verification, and the paper-book cutover. Offline final billing and Flutter are separate work packages.

| Phase | Indicative effort | Deliverable / exit condition |
| --- | --- | --- |
| 0. Discovery | 2–3 days | Sample books reviewed; products, units, cash flows, bill type, connectivity, printer, and accounting policy recorded |
| 1. Foundation | 4–5 days | Repository, CI, database migrations, authentication, permissions, API contract, staging |
| 2. Masters and openings | 3–4 days | Products, retailers, suppliers, account setup, opening import and validation |
| 3. Purchases and inventory | 6–7 days | Goods receipts, supplier bills/matching, batches, costs, shortages, stock movements |
| 4. Sales and documents | 6–7 days | Atomic issuing, stock allocation, credit bills, immediate tenders, PDF/print/share |
| 5. Money and corrections | 6–7 days | Collections, allocations, advances, supplier payments, returns, refunds, ledger |
| 6. Reports and settings | 4–5 days | Cashbook, expenses, statements, ageing, valuation, margins, language/settings |
| 7. Verification and operations | 5–6 days | Concurrency, reconciliation, security, actual printing, backups/restoration, deployment |
| 8. Pilot and cutover | 4–6 developer days across 1–2 weeks | Opening figures verified, staff trained, live pilot reconciled, ownership handed over |

Build posting and ledger foundations alongside phases 2–4; phase 5 completes settlement and correction workflows rather than introducing accounting after the fact.

First end-to-end milestone:

1. Receive 50 apple boxes at INR 1,200 per box.
2. Record the supplier bill and any freight.
3. Sell 5 boxes at INR 1,400 per box on credit.
4. Generate and share the INR 7,000 bill.
5. Later collect INR 2,000 cash and INR 1,000 UPI.
6. Verify 45 saleable boxes, INR 4,000 retailer due, correct cash/bank movements, remaining supplier due, and sold cost including allocated freight.
7. Repeat the same API requests and prove that no duplicate records or movements appear.

Demonstrate each milestone with realistic sample transactions before expanding to the next set of screens.

## 18. Verification and acceptance scenarios

Use meaningful service tests for money/posting rules, integration tests against real PostgreSQL, and browser end-to-end tests for complete workflows. Mocking the database alone does not test locking or constraints.

| Scenario | Expected result |
| --- | --- |
| Buy 50 boxes; sell 5 | Stock is 45; supplier and retailer positions are correct |
| Same SKU arrives at different rates | Batch costs remain distinct; actual sold allocations determine cost |
| Enter 1.5 boxes | Rejected by UI/API/database constraints |
| Supplier bills 50; receive 48 | Only 48 enter stock; discrepancy remains visible until resolved |
| Post supplier invoice after receipt | Stock does not increase a second time |
| Add freight after some boxes sold | Cost adjustment splits correctly between held stock and sold cost |
| Sell 5 boxes, collect later | Credit exists until a receipt is posted |
| Cash/UPI split receipt | One receipt, correct tender totals, correct account postings |
| Several receipts for one bill | Correct remaining amount, with no over-allocation |
| One receipt for several bills | Allocation total equals receipt, remainder becomes advance |
| Customer/supplier advance | Held and applied correctly, with no extra sales/purchases |
| Saleable return | Quantity restored at original attributable cost; credit recorded once |
| Damaged return | Not saleable; no duplicate impairment or refund |
| Cancel a paid or partially paid bill | Controlled deallocation/credit/refund and complete audit history |
| Two users sell the last boxes | One succeeds; the other receives a stock conflict |
| Two users allocate to the same due | No over-allocation or lost receipt |
| Double-click issue or lose response | Same idempotent result; one bill and one set of postings |
| PDF worker fails | Bill remains posted once; document can be regenerated |
| Staff requests owner cost report | Backend rejects access |
| Edit product/business wording | New documents change; old issued snapshots remain intact |
| Close day and attempt backdating | Rejected or handled through a permitted audited correction |
| Restore backup | Database, balances, files, and document references reconcile |

Proposed usability/performance targets, to measure on actual devices:

- Frequent repeat-retailer bill with 1–3 lines completed within about one minute after training.
- Ordinary posting requests complete within two seconds at the 95th percentile under the agreed concurrent load.
- PDF generation normally completes within ten seconds; pending status is explicit.
- Support at least five concurrent staff sessions in initial verification, adjusted to the actual staffing.
- Reconciliation tests have no unexplained stock or financial differences.

Production acceptance requires zero unresolved critical errors involving stock, money, permissions, or recovery. Obtain accountant review of the posting matrix and sample reports before treating estimated profit as an accepted business figure.

## 19. Migration from paper books and launch

1. Agree on a cutover date and archive/photograph historical books.
2. Clean and deduplicate retailer, supplier, and product records.
3. Physically count stock by SKU, batch where identifiable, condition, and location.
4. Agree opening cost estimates where historical costs are incomplete; label estimates.
5. Verify retailer dues, supplier dues, customer/supplier advances, cash, and bank balances.
6. Import unpaid opening items with original references and dates where available.
7. Validate imports in a dry run with row-level errors and source reconciliation totals.
8. Post an approved balanced opening batch; prevent importing the same batch twice.
9. Run a 1–2 week pilot and reconcile stock, collections, payables, and cash daily.
10. Fix differences and document how each was resolved.
11. At final cutover, choose either to retain the complete pilot ledger or reset and reimport a fresh opening snapshot. Do not count pilot transactions in both openings and live postings.
12. From the agreed cutover, enter every new transaction in the software and retain the old books as historical references.

Historical data entry can be a later project. Opening balances are not new sales, purchases, or collections.

Readiness gate for stopping daily book entry:

- Verified opening records and no unexplained reconciliations.
- All routine purchase, sale, credit, payment, return, and expense flows demonstrated.
- Staff can issue/share bills and collect payments without developer assistance.
- Printer and actual phone sharing verified.
- Recovery drill passed and owner can access exports/backups.
- Connectivity and power-continuity procedure tested.
- Support contact, incident process, and operational owner documented.

## 20. Costs, ownership, risks, and handover

### 20.1 Quote structure

Obtain separate prices for the browser/backend build, data migration, pilot/training, and post-launch support. Use the milestone acceptance criteria rather than a quote based only on screen count.

Recurring cost categories: API/worker hosting, PostgreSQL with backups/PITR, private document storage and egress, domain, monitoring, maintenance, and any later messaging provider. Hardware categories: counter device, tested printer, power backup, and backup internet.

Flutter, offline final billing, desktop packaging, and automatic WhatsApp delivery should have separate estimates. Hosting prices and message charges must be checked when selecting providers; this document is not a price quotation.

### 20.2 Main risks and responses

| Risk | Response |
| --- | --- |
| Incorrect opening dues | Party-level review and signed reconciliation before cutover |
| Duplicate submissions | Idempotent posting and unique source-event keys |
| Overselling boxes | Locked batch balances and transactional availability checks |
| Profit errors from freight or late bills | Landed-cost allocation, provisional flags, and cost-adjustment reconciliation |
| Treating UPI intent as receipt | Explicit confirmation and bank reconciliation |
| Internet/power outage | Tested backup connection/power; scoped offline package if required |
| Loss of database or documents | Independent backups and completed recovery drill |
| Staff bypassing the system | Short workflows, training, and daily closes with clear responsibility |
| Future mobile causing a rewrite | Versioned API, Dart contract check, and server-owned business rules |
| Regulatory/bill-format mismatch | Accountant-reviewed configuration and release samples |

### 20.3 Handover deliverables

- Source repository and owner-controlled hosting/database/storage accounts.
- Setup instructions, environment variable template, and pinned dependencies.
- Reviewed migrations, sample data, OpenAPI contract, and client generation instructions.
- Business rule and accounting posting documentation.
- Automated verification suite and its execution instructions.
- Deployment, recovery, backup, incident, and update procedures.
- Staff guide for bills, collections, purchases, corrections, and daily close.
- Instructions for editing English labels, bill wording, and business settings.
- Secure credential handover, support ownership, and an agreed maintenance period.
- Complete export of products, parties, stock movements, bills, payments, and ledger records.

## 21. Immediate implementation backlog

The next development work should proceed in this order:

- [ ] Review actual supplier bills, retailer bills, and ledger pages.
- [ ] Confirm stock location, users, counter devices, printer, connectivity, and bill/tax configuration.
- [ ] Finalise SKU/packing naming and discrepancy/costing/accounting policies.
- [ ] Scaffold React, NestJS, PostgreSQL, migrations, CI, and staging.
- [ ] Publish the initial OpenAPI contract and compile a small Dart client against it.
- [ ] Implement authentication, permissions, business settings, and master data.
- [ ] Implement balanced opening records and the ledger/posting foundation.
- [ ] Implement goods receipt, supplier invoice matching, stock batches, and cost allocation.
- [ ] Implement the complete first sale → shared bill → delayed cash/UPI receipt milestone.
- [ ] Add returns, refunds, advances, supplier settlement, expenses, and reconciliation reports.
- [ ] Verify concurrency, duplicate prevention, documents, security, and restore capability.
- [ ] Import approved balances, train staff, pilot, reconcile, and cut over.
- [ ] Begin the Flutter phase after the shared backend is proven in daily business use.

This plan intentionally makes the first production release a complete purchase-to-collection workflow. The future mobile application extends access to that same system.
