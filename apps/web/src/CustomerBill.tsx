import React from 'react';
import { formatBusinessDate } from './billDates';

export type CustomerBillData = {
  id: string;
  customer?: string;
  dealer?: string;
  bill_date?: string;
  total_due?: string;
  balance?: string;
  less_amount?: string;
  transport_charges?: string;
  sale_date?: string;
  created_at?: string;
  current_total?: string;
  previous_due?: string;
  total_bill?: string;
  amount_paid?: string;
  payment_discount?: string;
  items?: { fruit: string; quantity: number; quantity_unit?: 'box' | 'kg'; price_per_box: string; total_price: string }[];
};

const money = (amount: unknown) => `₹${Number(amount || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const quantity = (value: number, unit?: 'box' | 'kg') => `${Number(value || 0).toLocaleString('en-IN', { maximumFractionDigits: 3 })} ${unit === 'kg' ? 'kg' : 'boxes'}`;
export function CustomerBill({ bill }: { bill: CustomerBillData }) {
  const billDate = bill.sale_date || bill.bill_date;
  const date = formatBusinessDate(billDate);
  const dealer = Boolean(bill.dealer);
  const time = bill.created_at ? new Intl.DateTimeFormat('en-IN', { timeZone: 'Asia/Kolkata', hour: '2-digit', minute: '2-digit', hour12: true }).format(new Date(bill.created_at)) : '—';
  const quantities = (bill.items || []).reduce((totals, item) => {
    const unit = item.quantity_unit === 'kg' ? 'kg' : 'box';
    totals[unit] += Number(item.quantity || 0);
    return totals;
  }, { kg: 0, box: 0 });
  const quantitySummary = [quantities.kg ? quantity(quantities.kg, 'kg') : '', quantities.box ? quantity(quantities.box, 'box') : ''].filter(Boolean).join(' + ') || '0 boxes';
  const units = new Set((bill.items || []).map(item => item.quantity_unit === 'kg' ? 'kg' : 'box'));
  const costLabel = units.size > 1 ? 'Cost per unit' : units.has('kg') ? 'Cost per kg' : 'Cost per box';
  return <article className="customer-bill-document">
    <header className="invoice-header">{dealer && <span className="invoice-type">DEALER BILL</span>}<img src="/giri-fruits-logo.png" alt="Giri Fruits logo"/><div className="invoice-heading"><h1>గిరి ఫ్రూట్స్</h1><h2>ఏలూరు</h2><p>ఓవర్ బ్రిడ్జి డౌన్, దంరో పక్కన, ఏలూరు</p></div></header>
    <div className="invoice-meta"><span><b>Date:</b> {date}</span><span><b>Time:</b> {time}</span><span><b>Name:</b> {bill.customer || bill.dealer || '—'}</span><span><b>Bill no:</b> {dealer ? 'DB' : 'GF'}-{String(bill.id).padStart(5,'0')}</span></div>
    <p className="invoice-swipe-hint">Swipe the table sideways to see all columns</p>
    <div className="invoice-table-scroll" role="region" aria-label="Bill items; scroll horizontally for all columns" tabIndex={0}><table className="invoice-table"><thead><tr><th>S.No</th><th>Item</th><th>Quantity</th><th>{costLabel}</th><th>Total cost</th></tr></thead><tbody>{bill.items?.map((item,index)=><tr key={index}><td>{index+1}</td><td>{item.fruit}</td><td>{quantity(item.quantity, item.quantity_unit)}</td><td>{money(item.price_per_box)}</td><td>{money(item.total_price)}</td></tr>)}</tbody></table></div>
    <div className="invoice-totals"><div><span>Total quantity (మొత్తం శాల్తీలు)</span><b>{quantitySummary}</b></div><div><span>Total cost</span><b>{money((bill.items||[]).reduce((sum,item)=>sum+Number(item.total_price||0),0))}</b></div>{dealer&&Number(bill.transport_charges||0)>0&&<div><span>Transport charges</span><b>{money(bill.transport_charges)}</b></div>}{Number(bill.balance||0)>0&&<div><span>Additional amount</span><b>{money(bill.balance)}</b></div>}<div><span>Balance (బాకీ)</span><b>{money(bill.previous_due)}</b></div><div className="invoice-grand"><span>Total amount</span><b>{money(bill.total_bill ?? bill.total_due)}</b></div>{Number(bill.less_amount||0)>0&&<div><span>Less amount / Discount</span><b>−{money(bill.less_amount)}</b></div>}<div><span>Paid amount (చెల్లించిన అమౌంట్)</span><b>{money(bill.amount_paid)}</b></div><div className="invoice-grand"><span>To pay (చెల్లించాల్సిన అమౌంట్)</span><b>{money(Number(bill.total_bill ?? bill.total_due ?? 0) - Number(bill.amount_paid || 0) - Number(bill.payment_discount || 0))}</b></div></div>
  </article>;
}
