/** Dates are business dates in India, independent of the browser's timezone. */
export function indiaBusinessDate(now = new Date()): string {
  const parts = new Intl.DateTimeFormat('en-US', {timeZone:'Asia/Kolkata',year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(now);
  const value = (type: string) => parts.find(part => part.type === type)!.value;
  return `${value('year')}-${value('month')}-${value('day')}`;
}

/** Format an ISO business date for display without timezone conversion. */
export function formatBusinessDate(value: string | null | undefined): string {
  if (!value) return '—';
  const match = String(value).match(/^(\d{4})-(\d{2})-(\d{2})/);
  return match ? `${match[3]}-${match[2]}-${match[1]}` : String(value);
}

export function billPeriodRange(today: string, period: string): {from:string;to:string} {
  const [year,month,day]=today.split('-').map(Number);
  const date=new Date(Date.UTC(year,month-1,day));
  if(period.endsWith('d')) date.setUTCDate(date.getUTCDate()-(Number(period.slice(0,-1))-1));
  else if(period.endsWith('m')) {
    const targetMonth=month-1-Number(period.slice(0,-1));
    const lastDay=new Date(Date.UTC(year,targetMonth+1,0)).getUTCDate();
    date.setUTCDate(1); date.setUTCMonth(targetMonth); date.setUTCDate(Math.min(day,lastDay));
  }
  return {from:date.toISOString().slice(0,10),to:today};
}
