select top 100 * 
--into #robot
from DB05.on_user.dbo.Robotusers with (nolock)
where counter>10