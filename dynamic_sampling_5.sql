19-01-10 16:42:38,598 P29353 T19 INF     sqlalchemy.engine.base.Engine: select /*+  */ distinct invoice_eid, invoice_dt, receipt_dt, total_sum, act_total_sum, amount_to_pay, bad_debt_amount, effective_sum, rur_sum, receipt_sum_1c, status, paysys_name, paysys_id, paysys_certificate, firm_id, firm_title, person_name, person_inn, currency, client, client_suspect, manual_suspect, manager, manager_info, last_payment_dt, payment_number, payment_date, payment_term_dt, payment_sum, invoice_id, invoice_eid_exact, status_id, manager_code, hidden, is_fictive, paysys_cc, paysys_invoice_sendable, paysys_instant, client_email, passport_id, client_id, person_id, request_id, receipt_sum, receipt_status, credit, overdraft, market_postpay, fast_payment, contract_eid, contract_id, contract_commission, is_auto_invoice, parent_auto_invoice_id, parent_auto_invoice_eid, type, postpay, service_code from (SELECT
            invoices.*,
            pe.name AS person_name,
            pe.inn AS person_inn,
            c.manual_suspect,
            c.suspect AS client_suspect,
            c.internal internal_client,
            c.name AS client,
            c.email AS client_email
        FROM
            "BO"."V_UI_INVOICES" invoices,
            "BO"."T_CLIENT" c,
            "BO"."T_PERSON" pe
        WHERE
            c.id = invoices.client_id AND
            pe.id(+) = invoices.person_id
        ) inv where (invoice_dt >= :"1") and (invoice_dt - 1 < :"2") and (firm_id = :"3") and (exists (select /*+  */ 0 from t_consume c, t_order o where (inv.invoice_id = c.invoice_id) and (c.parent_order_id = o.id) and (o.service_id = :"4"))) and (internal_client = 0) order by receipt_dt desc fetch first :fetch rows only
19-01-10 16:42:38,598 P29353 T19 INF     sqlalchemy.engine.base.Engine: {'"1"': datetime.datetime(2018, 12, 3, 0, 0), '"2"': datetime.datetime(2019, 1, 10, 0, 0), '"4"': 37, 'fetch': 50, '"3"': '1'}

select * from gv$sqlarea where sql_fulltext like '%select /*+  */ distinct invoice_eid, invoice_dt, receipt_dt, total_sum, act_total_sum, amount_to_pay, bad_debt_amount%'
||'%) inv where (invoice_dt >= :"1") and (invoice_dt - 1 < :"2") and (firm_id = :"3") and (exists (select /*+  */ 0 from t_consume c, t_order o where (inv.invoice_id = c.invoice_id) and (c.parent_order_id = o.id) and (o.service_id = :"4"))) and (internal_client = 0) order by receipt_dt desc fetch first :fetch rows only%'


select * from dba_hist_sqltext where sql_id = 'dra65qfwcs00c'


select /*+ parallel(2) --dynamic_sampling(5) -- opt_param('optimizer_dynamic_sampling' '5') --parallel(2) --dynamic_sampling(@"SEL$AFF6DD2C" "I"@"SEL$9" 5) LEADING(@"SEL$AFF6DD2C" "I"@"SEL$9") INDEX_JOIN(@"SEL$AFF6DD2C" "I"@"SEL$9" DT RECEIPT_DT) --opt_param('_optimizer_push_pred_cost_based' 'false') */
distinct invoice_eid,
         invoice_dt,
         receipt_dt,
         total_sum,
         act_total_sum,
         amount_to_pay,
         bad_debt_amount,
         effective_sum,
         rur_sum,
         receipt_sum_1c,
         status,
         paysys_name,
         paysys_id,
         paysys_certificate,
         firm_id,
         firm_title,
         person_name,
         person_inn,
         currency,
         client,
         client_suspect,
         manual_suspect,
         manager,
         manager_info,
         last_payment_dt,
         payment_number,
         payment_date,
         payment_term_dt,
         payment_sum,
         invoice_id,
         invoice_eid_exact,
         status_id,
         manager_code,
         hidden,
         is_fictive,
         paysys_cc,
         paysys_invoice_sendable,
         paysys_instant,
         client_email,
         passport_id,
         client_id,
         person_id,
         request_id,
         receipt_sum,
         receipt_status,
         credit,
         overdraft,
         market_postpay,
         fast_payment,
         contract_eid,
         contract_id,
         contract_commission,
         is_auto_invoice,
         parent_auto_invoice_id,
         parent_auto_invoice_eid,
         type,
         postpay,
         service_code
  from (SELECT invoices.*,
               pe.name          AS person_name,
               pe.inn           AS person_inn,
               c.manual_suspect,
               c.suspect        AS client_suspect,
               c.internal       internal_client,
               c.name           AS client,
               c.email          AS client_email
          FROM "BO"."V_UI_INVOICES" invoices,
               "BO"."T_CLIENT"      c,
               "BO"."T_PERSON"      pe
         WHERE c.id = invoices.client_id
           AND pe.id(+) = invoices.person_id) inv
 where (invoice_dt >= date '2018-12-20')--(invoice_dt >= date '2018-12-03')
   and (invoice_dt - 1 < date '2019-01-10')
--   and (invoice_dt < date '2019-01-10' + 1)
   and (firm_id = 1)
   and (exists (select /*+  */
                 0
                  from BO.t_consume c, BO.t_order o
                 where (inv.invoice_id = c.invoice_id)
                   and (c.parent_order_id = o.id)
                   and (o.service_id = 37)))
   and (internal_client = 0)
 order by receipt_dt desc fetch first 50 rows only

select * from dba_ind_columns where table_name = 'T_INVOICE'
select * from dba_tab_col_statistics where table_name = 'T_INVOICE'
select * from dba_histograms where table_name = 'T_INVOICE' and column_name = 'FIRM_ID'
--T_INVOICE_RECEIPT_DT_IDX
select * from dba_views where view_name in ('V_UI_INVOICES')
