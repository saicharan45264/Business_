import React, { useEffect, useMemo, useRef, useState } from 'react';
import { toPng } from 'html-to-image';
import { jsPDF } from 'jspdf';
import { billPeriodRange, indiaBusinessDate, formatBusinessDate } from './billDates';

type Bill = { id: string; retailer_id?: string; dealer_id?: string; customer?: string; dealer?: string; sale_date?: string; bill_date?: string; current_total?: string; total_due?: string; previous_due?: string; amount_paid?: string; remaining?: number | string; payment_linkable?: boolean; items?: { product_id: string; fruit: string; quantity: number; price_per_box: string; total_price: string }[] };
type Payment = { id: string; payment_date: string | null; amount: string; discount?: string; cash: string | null; account: string | null; balance_before: string | null; balance_after: string | null; sale_id: string | null; dealer_bill_id?: string | null; source: string; deletable?: boolean };
type Entity = { id: string; name: string; opening_balance?: string; to_pay?: string };
type PaymentDraft = { total: string; cash: string; account: string; discount: string; date: string };
const fmt = (n: number) => `₹${n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const amount = (n: unknown) => Number(n || 0);

export function DirectoryStatement({ kind, entity, customers, dealers, onClose, onView, onPayment, onLoadPayments, onSetPaymentDate, onDeletePayment }: { kind: string; entity: Entity; customers: Bill[]; dealers: Bill[]; onClose: () => void; onView: (bill: Bill) => void; onPayment: (id: string, payment: { total: string; cash: string; account: string; discount: string; requestKey: string; paymentDate: string; billId?: string }) => Promise<void>; onLoadPayments: (id: string) => Promise<Payment[]>; onSetPaymentDate: (id: string, payment: Payment, date: string) => Promise<void>; onDeletePayment: (id: string, payment: Payment) => Promise<void> }) {
    const [view, setView] = useState<'bills' | 'payments'>('bills');
    const [payments, setPayments] = useState<Payment[]>([]);
    const [paymentError, setPaymentError] = useState('');
    const [paymentLoading, setPaymentLoading] = useState(false);
    const [paymentRefresh, setPaymentRefresh] = useState(0);
    const [dateEdit, setDateEdit] = useState('');
    const [dateValue, setDateValue] = useState('');
    const [savingDate, setSavingDate] = useState(false);
    const [period, setPeriod] = useState(''), [from, setFrom] = useState(''), [to, setTo] = useState(''), [busy, setBusy] = useState(false);
    const [showPaid, setShowPaid] = useState(false), [paying, setPaying] = useState(false);
    const [selectedBillId, setSelectedBillId] = useState('');
    const [draft, setDraft] = useState<PaymentDraft>({ total: '', cash: '0', account: '0', discount: '0', date: indiaBusinessDate() });
    const report = useRef<HTMLDivElement>(null);
    const isParty = kind === 'retailer' || kind === 'supplier';
    const partyLabel = kind === 'retailer' ? 'customer' : 'dealer';
    const sameDateBills = useMemo(() => {
        const bills = kind === 'retailer' ? customers : dealers;
        return bills.filter(b => b.payment_linkable !== false && String(kind === 'retailer' ? b.retailer_id : b.dealer_id) === String(entity.id)
            && String(kind === 'retailer' ? b.sale_date : b.bill_date).slice(0, 10) === draft.date);
    }, [kind, customers, dealers, entity.id, draft.date]);

    useEffect(() => {
        if (!isParty || view !== 'payments') return;
        let active = true;
        setPaymentLoading(true); setPaymentError('');
        onLoadPayments(entity.id).then(v => { if (active) setPayments(v) }).catch(() => { if (active) setPaymentError('Could not load payment history') }).finally(() => { if (active) setPaymentLoading(false) });
        return () => { active = false };
    }, [kind, view, entity.id, paymentRefresh]);

    const rows = useMemo(() => {
        const all = kind === 'retailer' ? customers : kind === 'supplier' ? dealers : [...dealers, ...customers];
        return all.flatMap(b => {
            const isDealer = !!b.dealer;
            const date = String(b.sale_date || b.bill_date || '').slice(0, 10);
            if ((from && date < from) || (to && date > to)) return [];
            if (kind === 'retailer' && String(b.retailer_id) !== String(entity.id) || kind === 'supplier' && String(b.dealer_id) !== String(entity.id)) return [];
            if (kind === 'fruit') return (b.items || []).filter(i => String(i.product_id) === String(entity.id)).map(i => ({ bill: b, date, isDealer, quantity: Number(i.quantity), total: Number(i.total_price), paid: 0, remaining: 0, totalOutstanding: 0 }));
            const paid = amount(b.amount_paid);
            const totalOutstanding = Math.max(0, amount(b.total_due ?? (amount(b.previous_due) + amount(b.current_total))) - paid);
            return [{ bill: b, date, isDealer, quantity: 0, total: amount(b.current_total), paid, remaining: amount(b.remaining), totalOutstanding }];
        }).sort((a, b) => b.date.localeCompare(a.date));
    }, [customers, dealers, kind, entity.id, from, to]);
    const sum = (filter: (r: typeof rows[number]) => boolean, key: 'total' | 'quantity' | 'remaining') => rows.filter(filter).reduce((n, r) => n + r[key], 0);
    const inRangePayments = payments.filter(p => p.payment_date ? (!from || p.payment_date >= from) && (!to || p.payment_date <= to) : !from && !to);

    async function download(format: 'pdf' | 'png') {
        if (!report.current || busy) return;
        setBusy(true);
        try {
            await document.fonts.ready;
            const data = await toPng(report.current, { pixelRatio: 2, backgroundColor: '#fff', filter: (node: any) => !node?.classList?.contains('statement-view') });
            const filename = `${entity.name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${view === 'payments' ? 'payments' : 'statement'}`;
            if (format === 'png') { const a = document.createElement('a'); a.href = data; a.download = `${filename}.png`; a.click(); }
            else { const pdf = new jsPDF({ unit: 'mm', format: 'a4' }); const img = pdf.getImageProperties(data); const width = 190, height = img.height * width / img.width; for (let y = 0; y < height; y += 277) { if (y) pdf.addPage(); pdf.addImage(data, 'PNG', 10, 10 - y, width, height); } pdf.save(`${filename}.pdf`); }
        } catch { window.alert('Could not download statement (స్టేట్‌మెంట్ డౌన్‌లోడ్ చేయలేకపోయాము)'); }
        finally { setBusy(false); }
    }

    async function submitPayment(e: React.FormEvent) {
        e.preventDefault();
        if (paying) return;
        const paise = (v: string) => Math.round(Number(v || 0) * 100);
        if (paise(draft.total) <= 0 || paise(draft.cash) < 0 || paise(draft.account) < 0 || paise(draft.cash) + paise(draft.account) !== paise(draft.total) || (kind === 'retailer' && paise(draft.discount) < 0)) {
            window.alert('Cash and account amounts must match the total paid (నగదు మరియు ఖాతా మొత్తం జమ అమౌంట్‌తో సమానంగా ఉండాలి)'); return;
        }
        if (sameDateBills.length > 1 && !selectedBillId) { window.alert('Choose which bill to update (దయచేసి బిల్లును ఎంచుకోండి)'); return; }
        setPaying(true);
        try {
            await onPayment(entity.id, { total: draft.total, cash: draft.cash, account: draft.account, discount: kind === 'retailer' ? draft.discount : '0', requestKey: crypto.randomUUID(), paymentDate: draft.date, billId: sameDateBills.length === 1 ? sameDateBills[0].id : selectedBillId || undefined });
            setDraft({ total: '', cash: '0', account: '0', discount: '0', date: indiaBusinessDate() });
            setShowPaid(false); setView('payments'); setPaymentRefresh(v => v + 1);
        } catch { /* Parent displays the API error and keeps this form open for retry. */ }
        finally { setPaying(false); }
    }

    if (showPaid && isParty) return <div className="modal" onClick={() => setShowPaid(false)}><div className="payment-details payment-entry-dialog" role="dialog" aria-modal="true" aria-labelledby="payment-entry-title" onClick={e => e.stopPropagation()}>
        <div className="payment-entry-heading"><div><p className="eyebrow">{partyLabel} account</p><h2 id="payment-entry-title">Enter paid amount</h2><p className="payment-entry-party">{entity.name}</p></div><button type="button" className="secondary" aria-label="Close payment form" onClick={() => setShowPaid(false)}>×</button></div>
        <form className="payment-entry-form" onSubmit={submitPayment}>
            <label>Payment date<input lang="en-GB" type="date" required value={draft.date} onChange={e => { setDraft(v => ({ ...v, date: e.target.value })); setSelectedBillId(''); }} /></label>
            {sameDateBills.length === 1 && <p className="payment-bill-match">This payment will be recorded on bill {kind === 'retailer' ? 'GF' : 'DB'}-{String(sameDateBills[0].id).padStart(5, '0')} for this date.</p>}
            {sameDateBills.length > 1 && <label>Bill for this date<select required value={selectedBillId} onChange={e => setSelectedBillId(e.target.value)}><option value="">Choose a bill</option>{sameDateBills.map(b => <option key={b.id} value={b.id}>{kind === 'retailer' ? 'GF' : 'DB'}-{String(b.id).padStart(5, '0')} · {fmt(amount(b.current_total))}</option>)}</select></label>}
            {sameDateBills.length === 0 && <p className="payment-bill-match">No active bill exists for this date. The payment will be recorded on the account.</p>}
            <label>Total paid (జమ)<input type="number" min="0.01" step="0.01" required value={draft.total} onChange={e => setDraft(v => ({ ...v, total: e.target.value, cash: e.target.value, account: '0' }))} /></label>
            {kind === 'retailer' && <label>Less amount / discount<input type="number" min="0" step="0.01" placeholder="0" value={draft.discount} onChange={e => setDraft(v => ({ ...v, discount: e.target.value }))} /><small>Discount reduces the customer’s outstanding balance.</small></label>}
            <div className="payment-entry-split"><label>Cash (నగదు)<input type="number" min="0" step="0.01" required value={draft.cash} onChange={e => { const value=e.target.value; setDraft(v => ({ ...v, cash:value, account:(Math.max(0,Math.round(Number(v.total||0)*100)-Math.round(Number(value||0)*100))/100).toFixed(2) })); }} /></label><label>Account (ఖాతా)<input type="number" min="0" step="0.01" required value={draft.account} onChange={e => { const value=e.target.value; setDraft(v => ({ ...v, account:value, cash:(Math.max(0,Math.round(Number(v.total||0)*100)-Math.round(Number(value||0)*100))/100).toFixed(2) })); }} /></label></div>
            <div className="payment-entry-actions"><button type="submit" disabled={paying}>{paying ? 'Saving…' : 'Save payment'}</button><button type="button" className="secondary" disabled={paying} onClick={() => setShowPaid(false)}>Cancel</button></div>
        </form>
    </div></div>;

    return <div className="modal" onClick={onClose}><div className="statement-paper" onClick={e => e.stopPropagation()}>
        <div className="statement-heading"><div><p className="eyebrow">Account statement</p><h2>{kind === 'fruit' ? 'Fruit' : kind === 'retailer' ? 'Customer' : 'Dealer'} statement — {entity.name}</h2></div>{isParty && <button type="button" onClick={() => { setDraft({ total:'',cash:'0',account:'0',discount:'0',date:indiaBusinessDate() }); setSelectedBillId(''); setShowPaid(true); }}>Enter paid amount (జమ)</button>}</div>
        <div className="bill-filters"><label>Show<select value={view} onChange={e => setView(e.target.value as 'bills'|'payments')}><option value="bills">View bills</option>{isParty && <option value="payments">View paid amounts</option>}</select></label><label>Period<select value={period} onChange={e => { const v=e.target.value; setPeriod(v); if(v){const r=billPeriodRange(indiaBusinessDate(),v);setFrom(r.from);setTo(r.to)}else{setFrom('');setTo('')} }}><option value="">All dates / custom</option>{[1,2,3,4,5,6,7,10,14,30].map(n=><option value={`${n}d`} key={n}>Last {n} {n===1?'day':'days'}</option>)}<option value="2m">Last 2 months</option><option value="3m">Last 3 months</option></select></label><label>From<input lang="en-GB" type="date" value={from} onChange={e=>{setPeriod('');setFrom(e.target.value)}} /></label><label>To<input lang="en-GB" type="date" value={to} onChange={e=>{setPeriod('');setTo(e.target.value)}} /></label></div>
        <div className="statement-scroll"><div className="statement-report" ref={report}><header className="invoice-header statement-brand"><img src="/giri-fruits-logo.png" alt="Giri Fruits logo"/><div className="invoice-heading"><h1>గిరి ఫ్రూట్స్</h1><h2>ఏలూరు</h2><p>ఓవర్ బ్రిడ్జి డౌన్, దంరో పక్కన, ఏలూరు</p></div></header><h2>{entity.name} — {kind === 'fruit' ? 'Fruit' : kind === 'retailer' ? 'Customer' : 'Dealer'} statement</h2><p>Period: {from ? formatBusinessDate(from) : 'All'} to {to ? formatBusinessDate(to) : 'All'}</p>
            {isParty && view === 'payments' ? <><div className="statement-summary-cards statement-current-balance"><div><small>Current to pay</small><strong>{fmt(amount(entity.to_pay))}</strong></div></div>{paymentLoading&&<p>Loading payment history…</p>}{paymentError&&<p role="alert">{paymentError}</p>}<div className="statement-table-wrap"><table className="invoice-table payment-history-table"><thead><tr><th>Payment date</th><th>Bill</th><th>Outstanding before</th><th>Paid</th>{kind==='retailer'&&<th>Discount</th>}<th>Cash</th><th>Account</th><th>Outstanding after</th><th>Type</th>{kind==='retailer'&&<th>Action</th>}</tr></thead><tbody>{inRangePayments.map(p=>{const billId=kind==='retailer'?p.sale_id:p.dealer_bill_id;const bill=(kind==='retailer'?customers:dealers).find(c=>String(c.id)===String(billId));return <tr key={`${p.source}-${p.id}`}><td>{formatBusinessDate(p.payment_date)} {p.source==='recorded'&&<button type="button" className="payment-info statement-view" aria-label="Edit payment date" onClick={()=>{setDateEdit(`${p.source}-${p.id}`);setDateValue(p.payment_date||indiaBusinessDate())}}>d</button>}{dateEdit===`${p.source}-${p.id}`&&<div className="payment-date-editor"><input lang="en-GB" type="date" value={dateValue} onChange={e=>setDateValue(e.target.value)}/><button type="button" disabled={savingDate||!dateValue} onClick={async()=>{setSavingDate(true);try{await onSetPaymentDate(entity.id,p,dateValue);setDateEdit('');setPaymentRefresh(v=>v+1)}catch{window.alert('Could not update payment date')}finally{setSavingDate(false)}}}>Save</button><button type="button" className="secondary" onClick={()=>setDateEdit('')}>Cancel</button></div>}</td><td>{billId?(bill?<button type="button" className="link-button" onClick={()=>onView(bill)}>{kind==='retailer'?'GF':'DB'}-{String(billId).padStart(5,'0')}</button>:`${kind==='retailer'?'GF':'DB'}-${String(billId).padStart(5,'0')}`):'—'}</td><td>{p.balance_before===null?'—':fmt(amount(p.balance_before))}</td><td>{fmt(amount(p.amount))}</td>{kind==='retailer'&&<td>{amount(p.discount)>0?fmt(amount(p.discount)):'—'}</td>}<td>{p.cash===null?'—':fmt(amount(p.cash))}</td><td>{p.account===null?'—':fmt(amount(p.account))}</td><td>{p.balance_after===null?'—':fmt(amount(p.balance_after))}</td><td>{p.source==='earlier bill payment'?'Bill payment':amount(p.discount)>0?'Payment + discount':amount(p.amount)<0?'Payment correction':'Payment'}</td>{kind==='retailer'&&<td>{p.deletable&&<button type="button" className="statement-delete statement-view" disabled={savingDate} onClick={async()=>{if(!window.confirm('Delete this payment? The customer balance and linked bill totals will be recalculated.'))return;setSavingDate(true);try{await onDeletePayment(entity.id,p);setPaymentRefresh(v=>v+1)}catch{window.alert('Could not delete this payment')}finally{setSavingDate(false)}}}>Delete</button>}</td>}</tr>})}</tbody></table></div>{!paymentLoading&&!paymentError&&!inRangePayments.length&&<p className="statement-empty">No recorded payments for this date range.</p>}</> : <>{kind==='fruit'?<div className="statement-summary-cards"><div><small>Boxes ordered</small><strong>{sum(r=>r.isDealer,'quantity')}</strong></div><div><small>Boxes delivered</small><strong>{sum(r=>!r.isDealer,'quantity')}</strong></div><div><small>Ordered cost</small><strong>{fmt(sum(r=>r.isDealer,'total'))}</strong></div><div><small>Delivered cost</small><strong>{fmt(sum(r=>!r.isDealer,'total'))}</strong></div></div>:<div className="statement-summary-cards"><div><small>Total bills in range</small><strong>{fmt(sum(()=>true,'total'))}</strong></div><div><small>Remaining on these bills</small><strong>{fmt(sum(()=>true,'remaining'))}</strong></div><div><small>Current to pay</small><strong>{fmt(amount(entity.to_pay))}</strong></div></div>}<div className="statement-table-wrap"><table><thead><tr><th>Date</th><th>Bill</th>{kind==='fruit'?<><th>Transaction</th><th>Dealer / customer</th><th>Boxes</th><th>Price per box</th><th>Total cost</th></>:<><th>Bill amount</th><th>Paid</th><th>Total outstanding</th></>}<th>Details</th></tr></thead><tbody>{rows.map((r,i)=><tr key={i}><td>{formatBusinessDate(r.date)}</td><td>{r.isDealer?'DB':'GF'}-{String(r.bill.id).padStart(5,'0')}</td>{kind==='fruit'?<><td>{r.isDealer?'Ordered':'Delivered'}</td><td>{r.bill.dealer||r.bill.customer}</td><td>{r.quantity}</td><td>{fmt(r.total/r.quantity||0)}</td><td>{fmt(r.total)}</td></>:<><td>{fmt(r.total)}</td><td>{fmt(r.paid)}</td><td>{fmt(r.totalOutstanding)}</td></>}<td><button className="link-button statement-view" onClick={()=>onView(r.bill)}>View bill</button></td></tr>)}</tbody></table></div>{!rows.length&&<p className="statement-empty">No bills found for this date range.</p>}{kind==='fruit'&&<p>Includes fruit recorded on active customer and dealer bills.</p>}</>}
        </div></div>
        <div className="bill-actions"><button disabled={busy||(view==='payments'&&(paymentLoading||!!paymentError))} onClick={()=>void download('pdf')}>{busy?'Preparing…':'Save PDF'}</button><button disabled={busy||(view==='payments'&&(paymentLoading||!!paymentError))} onClick={()=>void download('png')}>Save image</button><button className="secondary" onClick={onClose}>Close</button></div>
    </div></div>;
}
