--Liczba wnioskow wg dni - TABELA REFERENCYJNA
WITH AO_Cnt AS (
     select
       to_char(data_wysylki, 'YYYY') AS ROK,
       to_char(data_wysylki, 'Q') AS KWARTAL,
       to_char(data_wysylki, 'MM') AS MIESIAC,
       to_char(data_wysylki, 'WW') AS TYDZIEN,
       to_char(data_wysylki, 'DD') AS DZIEN,
       to_char(data_wysylki, 'ID') AS DZIEN_TYGODNIA,
       count(distinct w.id) AS LiczbaWnioskow
from wnioski_poprawne w
join analiza_operatora ap
    on w.id = ap.id_wniosku
group by 1,2,3,4,5,6
order by 1 desc)

/*
--Liczba wnioskow w miesiacu z podzialem na rok
select ROK, DZIEN, sum(LiczbaWnioskow) from AO_Cnt
where ROK = '2015' AND MIESIAC = '05'
group by 1,2
--Wiekszosc wnioskow z bledna data zostalo utworzonych 15/05/2015
*/
/*
--Liczba wnioskow wg lat
select distinct
       ROK,
       sum(LiczbaWnioskow) over (partition by rok) as LiczbaWnioskow,
       100*Round((sum(LiczbaWnioskow) over (partition by rok)) / (sum(LiczbaWnioskow) over ()),2) as "%Total"
from AO_Cnt
order by 1 desc,2 desc;
--Najwieksza liczba wnioskow wystapila w 2015 roku
*/
/*
--Liczba wnioskow w miesiacu z podzialem na rok
select distinct
       ROK,
       MIESIAC,
       sum(LiczbaWnioskow) over (partition by rok, MIESIAC) as LiczbaWnioskow,
       100*Round((sum(LiczbaWnioskow) over (partition by rok, MIESIAC)) / (sum(LiczbaWnioskow) over (partition by rok)),2) as "%Total"
from AO_Cnt
order by 1 desc,2 desc;
--Uwaga na rok 2018 i 2013, bo te lata sa niepelne (tylko 2mce) i % sa wysokie/niskie
*/
/*
--Liczba wnioskow w miesiacu
select distinct
       MIESIAC,
       sum(LiczbaWnioskow) over (partition by MIESIAC) as LiczbaWnioskow,
       100*Round((sum(LiczbaWnioskow) over (partition by MIESIAC)) / (sum(LiczbaWnioskow) over ()),2) as "%Total"
from AO_Cnt
order by 1 desc;
--Zwiekszona liczba wnioskow wystepuje w miesiacach wakacyjnych - lip, sie, wrz
*/
/*
--Liczba wnioskow wg dni tygodnia
select distinct
       dzien_tygodnia,
       sum(LiczbaWnioskow) over (partition by DZIEN_TYGODNIA) as LiczbaWnioskow,
       100 * ROUND ((sum(LiczbaWnioskow) over (partition by DZIEN_TYGODNIA))
                / (sum(LiczbaWnioskow) over ()),2) AS "%Total"
from AO_Cnt
order by 1;
--Wiecej wnioskow pojawia sie w dni pracujace pon-pt niz w weekend, ale zaden dzien pracujacy nie jest wyrozniony
*/