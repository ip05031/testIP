/**
 * Genera el PDF de la Orden de Compra con datos dinámicos.
 * @param {Array} items - Lista de objetos {qty, item, desc, cost, amount}
 * @param {Object} info - Datos generales {oc, fecha, proveedor, direccion, goodThru, terms}
 * @param {String} totalTxt - El total general formateado (ej: "$3,000.00")
 */
function generarPDF(items, info, totalTxt) {
    window.jsPDF = window.jspdf.jsPDF;

    const doc = new jsPDF({
        orientation: 'p',
        unit: 'pt',
        format: 'letter'
    });

    const margenIzquierdo = 40;
    const verdeFeco = [76, 145, 105];
    const verdeClaro = [170, 209, 163];

    // --- 1. ENCABEZADO ---
    doc.setFontSize(8).setFont("helvetica", "normal").setTextColor(0).text("ORDERED BY:", margenIzquierdo, 60);
    doc.setFontSize(12).setFont("helvetica", "bold").text("FECO, S.A. DE C.V.", margenIzquierdo, 75);
    doc.setFontSize(9).setFont("helvetica", "normal")
        .text("Av. Lamatepec y Calle Chaparr.\n#3, Urb. Ind Sta Elena\nAntiguo Cuscatlan\nEl Salvador\n\nVoice: 76113756\nFax:", margenIzquierdo, 88);

    doc.setFontSize(28).setTextColor(verdeFeco[0], verdeFeco[1], verdeFeco[2]).setFont("helvetica", "bold")
        .text("PURCHASE", 400, 70).text("ORDER", 400, 95);

    const formatearFecha = (fecha) => fecha.split('-').reverse().join('/');
    const fecha1 = formatearFecha(info.fecha);
    const fecha2 = formatearFecha(info.goodThru);

    doc.setFontSize(10).setTextColor(0).setFont("helvetica", "normal")
        .text(`Purchase Order No.: ${info.oc}`, 400, 115)
        .text(`Date Issued: ${fecha1}`, 400, 130);

    // --- 2. SECCIONES TO / SHIP TO ---
    // Sección TO (Proveedor dinámico)
    doc.setFillColor(verdeClaro[0], verdeClaro[1], verdeClaro[2]);
    doc.rect(margenIzquierdo, 160, 240, 15, 'F'); doc.rect(margenIzquierdo, 160, 240, 80);
    doc.setFont("helvetica", "bold").text("To:", margenIzquierdo + 5, 171);
    doc.setFont("helvetica", "normal");

    // Dividir dirección del proveedor para que no se salga del cuadro
    const vendorAddr = doc.splitTextToSize(`${info.proveedor}\n${info.direccion}\n\nEL SALVADOR`, 230);
    doc.text(vendorAddr, margenIzquierdo + 5, 188);

    // Sección SHIP TO (Fijo)
    doc.setFillColor(verdeClaro[0], verdeClaro[1], verdeClaro[2]);
    doc.rect(330, 160, 240, 15, 'F'); doc.rect(330, 160, 240, 80);
    doc.setFont("helvetica", "bold").text("Ship To:", 335, 171);
    doc.setFont("helvetica", "normal").text("FECO, S.A. DE C.V.\nAv. Lamatepec y Calle Chaparr.\n#3, Urb. Ind Sta Elena\nAntiguo Cuscatlan\nEl Salvador", 335, 188);

    // --- 3. BARRA DE TÉRMINOS ---
    const yTerminos = 245;
    doc.setFillColor(verdeClaro[0], verdeClaro[1], verdeClaro[2]);
    doc.rect(margenIzquierdo, yTerminos, 530, 15, 'F'); doc.rect(margenIzquierdo, yTerminos, 530, 30);
    doc.line(140, yTerminos, 140, yTerminos + 30); doc.line(240, yTerminos, 240, yTerminos + 30); doc.line(380, yTerminos, 380, yTerminos + 30);

    doc.setFont("helvetica", "bold")
        .text("Good Thru", 65, yTerminos + 11)
        .text("Ship Via", 170, yTerminos + 11)
        .text("Account No.", 280, yTerminos + 11)
        .text("Terms", 460, yTerminos + 11);

    doc.setFont("helvetica", "normal")
        .text(fecha2, 60, yTerminos + 26)
        .text("Airborne", 165, yTerminos + 26)
        .text(info.terms || "Net 30 Days", 450, yTerminos + 26);

    // --- 4. TABLA DINÁMICA DE ÍTEMS ---
    const yTabla = 285;
    const altoTablaMax = 430;
    doc.setFillColor(verdeClaro[0], verdeClaro[1], verdeClaro[2]);
    doc.rect(margenIzquierdo, yTabla, 530, 15, 'F');
    doc.rect(margenIzquierdo, yTabla, 530, altoTablaMax);

    // Encabezados
    doc.setFont("helvetica", "bold")
        .text("Quantity", 55, yTabla + 11)
        .text("Item", 150, yTabla + 11)
        .text("Description", 280, yTabla + 11)
        .text("Unit Cost", 435, yTabla + 11)
        .text("Amount", 515, yTabla + 11);

    doc.setFont("helvetica", "normal");
    let yActual = yTabla + 25;
    const anchoDesc = 200;

    items.forEach(obj => {
        const lineasDesc = doc.splitTextToSize(obj.desc, anchoDesc);
        const lineasItem = doc.splitTextToSize(obj.item, 90);

        const altoDesc = doc.getTextDimensions(lineasDesc).h;
        const altoItem = doc.getTextDimensions(lineasItem).h;
        const altoMaximoFila = Math.max(altoDesc, altoItem);

        // Verificar si se sale del área de la tabla (opcional: control de salto de página)
        if (yActual + altoMaximoFila > yTabla + altoTablaMax - 10) {
            return; // Evita escribir sobre el total si hay demasiados items
        }

        doc.text(obj.qty.toString(), 80, yActual, { align: "right" });
        doc.text(lineasItem, 115, yActual);
        doc.text(lineasDesc, 215, yActual);
        doc.text(parseFloat(obj.cost).toLocaleString('en-US', { minimumFractionDigits: 2 }), 485, yActual, { align: "right" });
        doc.text(parseFloat(obj.amount).toLocaleString('en-US', { minimumFractionDigits: 2 }), 560, yActual, { align: "right" });

        yActual += altoMaximoFila + 15; // Espaciado entre filas
    });

    // Líneas verticales de la tabla
    doc.line(110, yTabla, 110, yTabla + altoTablaMax);
    doc.line(210, yTabla, 210, yTabla + altoTablaMax);
    doc.line(420, yTabla, 420, yTabla + altoTablaMax);
    doc.line(500, yTabla, 500, yTabla + altoTablaMax);

    // --- 5. TOTAL ---
    const yTotal = yTabla + altoTablaMax;
    doc.setFillColor(255, 255, 255);
    doc.rect(420, yTotal - 20, 150, 20, 'FD');
    doc.setFont("helvetica", "bold").text("TOTAL", 430, yTotal - 7);
    doc.setFontSize(11).text(totalTxt, 560, yTotal - 7, { align: "right" });

    // --- 6. FIRMA ---
    doc.setFontSize(9).text("Authorized Signature", margenIzquierdo, 745);
    doc.line(130, 745, 300, 745);

    doc.save(`Orden_Compra_${info.oc}.pdf`);


}