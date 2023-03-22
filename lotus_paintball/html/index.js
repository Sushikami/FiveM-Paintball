$(document).ready(function() {
	window.addEventListener('message', function(event) {
		switch(event.data.action) {
			case "toggleUi": // Show UI if paintball player
				const showUi = event.data.value;
				$("#playerListTable").css("display", showUi?"block":"none");
				break;
			case "update": // Update UI information
				$("#playerlist").empty();
				$("#overallHeader").empty();
				$("#overallScore").empty();
				const teams = event.data.value;
				for(var team in teams) {
					$("#overallHeader").append(`<th>[ Team ${team} ]</th>`);
					const players = event.data.value[team].Players;
					var teamScore = 0;
					for(var player in players) {
						if(players[player] != null) {
							const p = players[player];
							teamScore += p.Score;

							const color = p.Ready?'#0F0':'#666';
							$("#playerlist").append(`<tr style="color: ${color};"><td>[ ${team} ]</td><td>[ ${p.Name} ]</td><td>[ ${p.Score} ]</td><td>[ ${p.Ping}ms ]</td></tr>`);
						}
					}
					$("#overallScore").append(`<th><h1>${teamScore}</h1></th>`);
				}
				break;
			case "announce": // Custom announcement UI
        console.log(event.data)
				break;
		}
	});
});
