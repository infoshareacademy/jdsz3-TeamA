create table KALENDARZ AS (
select generate_series(
           (date '2013-01-01'),
           (date '2018-12-31'),
           interval '1 day'
         ) as DATY);

select
       max(data_wysylki),
       min(data_wysylki)
from analiza_operatora;

select k.daty
from KALENDARZ k

WITH KALENDARZ AS (
    SELECT * FROM KALENDARZ
),
WNIOSKI AS (
select
       W.ID,
       AW.data_utworzenia,
       AW.data_zakonczenia
from wnioski_poprawne w
join analizy_wnioskow aw
on w.id = aw.id_wniosku)

SELECT *,
       TRUNC(W.data_utworzenia, 'DAY')
FROM KALENDARZ K
LEFT JOIN WNIOSKI W
ON K.DATY >= W.data_utworzenia
AND K.DATY <= W.data_zakonczenia
WHERE ID = 37082