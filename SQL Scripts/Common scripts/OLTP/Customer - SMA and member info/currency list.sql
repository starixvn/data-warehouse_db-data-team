select currency SystemCurrency,Code StandardCode , Description, e.MultipliedBy
from Exchange e
where exchangeid not in (27,28,20)
order by 1