select wm.name as wine_maker, v.name as vineyard,
s.name as style, c.name as comment, g.name as grape, w.vintage, w.rating
from wines w, wine_makers wm, vineyards v, styles s, comments c, grapes g
where w.wine_maker_id = wm.id
and w.vineyard_id = v.id
and w.style_id = s.id
and w.comment_id = c.id
and w.grape_id = g.id
and (w.rating = '4' or w.rating = '4.5')
and w.review_date >= '2017-01-01'
order by wine_maker, vineyard, vintage;
