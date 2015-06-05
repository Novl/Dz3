var MAX = 30;
var MIN = 1;
var SIZE=30;
var req_new_player= "/api/server/req_new_player/";
var json_get_table="api/server/json_read_table/";
var json_get_state="/api/server/json_get_state/"
var json_make_move="/api/server/json_make_move/";
var json_get_players="/api/server/json_get_players/";
var new_game="/api/server/refresh/";
var COLORS = ["#AAAADD","red","green","blue","yellow","black"];
var MY_NUMBER;
var State=1;

function authentification(new_pl_name)
{
	$.ajax({
		url:req_new_player+new_pl_name,
		dataType: "json",
		async:"false"
		}).done(function(data){
	if (data.Exit_code=="0")
			{
				MY_NUMBER=data.num;
				alert("Welcome");
				//---------------------- CREATING INFO
				$("#p_name").html("Your name is: <font color=\"red\">"+$("#player_name").val()+" (your number:"+MY_NUMBER+")<br><br> Your color:");
				$("#p_name").attr("NUM",MY_NUMBER);
				
				var TABLE_MENU=$("#tab_with_color");
				TABLE_MENU.empty();
				var TABLE_MENU_TR=$("<tr>");
				var TABLE_MENU_TD=$("<td>");
				TABLE_MENU_TR.attr("height",SIZE+"px");
				TABLE_MENU_TD.attr("width",SIZE+"px");
				TABLE_MENU_TD.appendTo(TABLE_MENU_TR);
				TABLE_MENU_TR.appendTo(TABLE_MENU);
				TABLE_MENU_TD.attr("bgcolor",COLORS[MY_NUMBER]);
				
				$("#new_player").css("visibility","hidden");
				$("#player_name").css("visibility","hidden");
				$(".registered").css("visibility","visible");
				//------------------------END CREATING INFO------------------
				
				Re_draw_table();
				update_state();
			}
			else 
				alert("Already full");	
			})
}
function Move(CELL)
{
	$.ajax({
		url:json_make_move+String(MY_NUMBER)+"/"+CELL,
		dataType: "json",
		async:"false"
		}).done(function(data){
		if (data.Result=="Not available")
				alert("Not available");
			else
				if (data.Result=="Not your turn")
					alert("Not your turn");
				else
					$("#"+CELL).attr("bgcolor",COLORS[MY_NUMBER]);
	})
};

function Re_draw_table()
{
		$.ajax({
			url:json_get_table,
			dataType: "json",
			async:"false"
			}).done(function(data)
			{
			// ---------------------- DROWING TABLE---------------------
				var table= $("table#play_board");
				table.empty();
				table.attr("width",((MAX+1)*SIZE)+"px");
		
				for (var i=MIN; i<=MAX; i++) 
				{
					var new_str=$("<tr>");
					new_str.appendTo($(table));
					new_str.attr("height",SIZE+"px");

					for (var j=MIN; j<=MAX; j++)
					{
						var new_col=$("<td>");
						new_col.attr("width",SIZE+"px");
						new_col.attr("id",Number(MAX*(i-1)+j));
						new_col.click(function(){Move(this.id);})
						
						new_col.addClass("cells");
						new_col.attr("bgcolor",COLORS[Number(data[Number(MAX*(i-1)+j)])]);
						new_col.appendTo(new_str);
					}
				}
				//--------------------------END DROWING TABLE----------------------------------
			})
};


function update_state(){
//-------------UPDATE STATE------------
		$.ajax({
			url:json_get_state,
			dataType: "json",
			async:"false"
			}).done(function(data){
				if (data.State==0)
				{
					alert("Winner :"+data.Winner);
					$("#new_player").css("visibility","visible");
					
					$("#new_player").attr("value","New game");
					$("#new_player").unbind("click");
					$("#new_player").click(function(){
					$.ajax({
						url:new_game,
						dataType: "json",
						async:"false"
						}).done(function(data1)
						{
							if (data1.Status=="ok")
								{
									$("#new_player").unbind("click");
									$("#new_player").click(function(){authentification($("#player_name").val())});
									$("#new_player").attr("value","Enter game");
									$(".unregistered").css("visibility","visible");
									$(".registered").css("visibility","hidden");
								}
							else
							{
								alert("New game was started go to url:\"localhost:8090\" to join");
								$("#new_player").unbind("click");
								$("#new_player").click(function(){authentification($("#player_name").val())});
								$("#new_player").attr("value","Enter game");
								$(".unregistered").css("visibility","visible");
								$(".registered").css("visibility","hidden");
							}
						})
				})
				}
				else
					setTimeout(function(){Re_draw_table(); update_state();}, 2000);
			State=data.State;
			$("#State").text("Turn player number: "+State);
		})
		$.ajax({
			url:json_get_players,
			dataType: "json",
			async:"false"
			}).done(function(data){
				var table_pl=$("#table_players");
				table_pl.empty();
				table_pl.addClass("registered");
				for (var i=1; i<=5; i++)
				{
					if (data[i]!=0)
					{
						var tr=$("<tr>");
						var td=$("<td>");
						td.text(i);
						td.appendTo(tr);
						var td=$("<td>")
						td.text(data[i]);
						td.css("color",COLORS[i]);
						td.appendTo(tr);
						tr.appendTo(table_pl);
					}
				}
			
			
			})
		//-------------------END UPDATE STATE-------------
}

$(document).ready(function(){
	$(".registered").css("visibility","hidden");
	//-------------------------GENERATING ACTIONS--------------------	
	$("#new_player").click(function(){authentification($("#player_name").val())});	
	//------------------------END GENERATING ACTIONS------------------
	}
)
	
	


	