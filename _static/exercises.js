function toggleVisible (x) {
    if (x.style.display === "none") {
        x.style.display = "block";
    } else {
        x.style.display = "none";
    }
}

window.onload = function () {
    for (let o of $('.solution>.first')) {
        solution = o.nextElementSibling;
        o.onclick = function() { toggleVisible(solution); };
    }
}
