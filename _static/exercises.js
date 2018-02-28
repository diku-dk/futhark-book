function toggleVisible (x) {
    if (x.style.display === "none") {
        x.style.display = "block";
    } else {
        x.style.display = "none";
    }
}

window.onload = function () {
    solutions = $('.solution>.first');
    for (let o of solutions) {
        solution = o.nextElementSibling;
        o.onclick = function() { toggleVisible(solution); };
    }
}
