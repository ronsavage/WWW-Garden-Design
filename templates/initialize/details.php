<table align = 'center'>
	<tr>
		<td colspan = '3'><div class = 'blue_centered'>Details</div><br /></td>
	</tr>
	<tr>
		<td rowspan = '7'>
			<table class = 'table_margin_auto'>
				<tr>
					<td><span id = 'details_thumbnail'></span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
				</tr>
			</table>
		</td>
		<td>
			<table class = 'table_margin_auto'>
				<tr>
					<td>Common name:</td>
					<td align = 'left'><input id = 'details_common_name' type = 'text' size = '50' maxlength = '100'></td>
				</tr>
				<tr>
					<td>Scientific name:</td>
					<td align = 'left'><input id = 'details_scientific_name' type = 'text' size = '50' maxlength = '100'></td>
				</tr>
				<tr>
					<td>Aliases:</td>
					<td align = 'left'><input id = 'details_aliases' type = 'text' size = '50' maxlength = '255'></td>
				</tr>
				<tr>
					<td>Height:</td>
					<td align = 'left'><input id = 'details_height' type = 'text' size = '10'></td>
				</tr>
				<tr>
					<td>Width:</td>
					<td align = 'left'><input id = 'details_width' type = 'text' size = '10'></td>
				</tr>
				<tr>
					<td>
						<br>
					</td>
				</tr>
				<tr>
					<td align = 'center'><input type = 'reset'  value = 'Reset'  /></td>
					<td align = 'center'><%= submit_button 'Save' %></td>
				</tr>
			</table>
		</td>
	</tr>
</table>

<div id = 'details_result_div'></div>