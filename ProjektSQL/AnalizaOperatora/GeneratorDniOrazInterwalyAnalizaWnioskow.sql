create table KALENDARZ AS (
select generate_series(
           (date '2014-01-01'),
           (date '2017-12-31'),
           interval '1 day'
         )::date as DATY);

WITH KALENDARZ AS (
    SELECT * FROM KALENDARZ
),
WNIOSKI AS (
select
       W.ID,
       W.data_utworzenia::date,
       AW.data_zakonczenia::date
from wnioski_poprawne w
join analizy_wnioskow aw
on w.id = aw.id_wniosku)

SELECT daty as data, count(distinct w.id)
FROM KALENDARZ K
LEFT JOIN WNIOSKI W
ON K.DATY >= W.data_utworzenia
AND K.DATY <= W.data_zakonczenia
where to_char(daty, 'YYYY') = '2014'
group by 1
order by 1 desc