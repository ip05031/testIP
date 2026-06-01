/**
 * Genera el PDF de la Orden de Compra con formato de tabla completa.
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
    
    // Configuración de la estructura fija
    const yInicioTablaNormal = 285; // Para página 1
    const yInicioTablaSiguientes = 160; // Para páginas 2 en adelante
    const yPiePagina = 720; // Donde termina la tabla (fondo de la hoja)
    const limiteSalto = 700; // Punto donde decide saltar de página

    // Función interna para el encabezado de empresa
    const dibujarEncabezadoPrincipal = (pagina) => {
        doc.setFontSize(8).setFont("helvetica", "normal").setTextColor(0).text("ORDERED BY:", margenIzquierdo, 60);
        doc.setFontSize(12).setFont("helvetica", "bold").text("FECO, S.A. DE C.V.", margenIzquierdo, 75);
        doc.setFontSize(9).setFont("helvetica", "normal")
            .text("Av. Lamatepec y Calle Chaparr.\n#3, Urb. Ind Sta Elena\nAntiguo Cuscatlan\nEl Salvador\n\nVoice: 76113756\nFax:", margenIzquierdo, 88);

        doc.setFontSize(28).setTextColor(verdeFeco[0], verdeFeco[1], verdeFeco[2]).setFont("helvetica", "bold")
            .text("PURCHASE", 400, 70).text("ORDER", 400, 95);

        const formatearFecha = (f) => f ? f.split('-').reverse().join('/') : "";
        doc.setFontSize(10).setTextColor(0).setFont("helvetica", "normal")
            .text(`Purchase Order No.: ${info.oc}`, 400, 115)
            .text(`Date Issued: ${formatearFecha(info.fecha)}`, 400, 130);
        
        doc.setFontSize(8).text(`Página ${pagina}`, 530, 40);
    };

    const dibujarBloquesInformacion = () => {
        // Cuadros To / Ship To
        doc.setFillColor(verdeClaro[0], verdeClaro[1], verdeClaro[2]);
        doc.rect(margenIzquierdo, 160, 240, 15, 'F'); doc.rect(margenIzquierdo, 160, 240, 80);
        doc.setFont("helvetica", "bold").text("To:", margenIzquierdo + 5, 171);
        doc.setFont("helvetica", "normal");
        const vendorAddr = doc.splitTextToSize(`${info.proveedor}\n${info.direccion}\n\nEL SALVADOR`, 230);
        doc.text(vendorAddr, margenIzquierdo + 5, 188);

        doc.setFillColor(verdeClaro[0], verdeClaro[1], verdeClaro[2]);
        doc.rect(330, 160, 240, 15, 'F'); doc.rect(330, 160, 240, 80);
        doc.setFont("helvetica", "bold").text("Ship To:", 335, 171);
        doc.setFont("helvetica", "normal").text("FECO, S.A. DE C.V.\nAv. Lamatepec y Calle Chaparr.\n#3, Urb. Ind Sta Elena\nAntiguo Cuscatlan\nEl Salvador", 335, 188);

        const yT = 245;
        const formatearFecha = (f) => f ? f.split('-').reverse().join('/') : "";
        doc.setFillColor(verdeClaro[0], verdeClaro[1], verdeClaro[2]);
        doc.rect(margenIzquierdo, yT, 530, 15, 'F'); doc.rect(margenIzquierdo, yT, 530, 30);
        doc.line(140, yT, 140, yT + 30); doc.line(240, yT, 240, yT + 30); doc.line(380, yT, 380, yT + 30);
        doc.setFont("helvetica", "bold")
            .text("Good Thru", 65, yT + 11).text("Ship Via", 170, yT + 11).text("Proyecto. ", 280, yT + 11).text("Terms", 460, yT + 11);
        doc.setFont("helvetica", "normal")
            .text(formatearFecha(info.goodThru), 60, yT + 26).text("Airborne", 165, yT + 26).text(info.proyecto || "", 270, yT + 26).text(info.terms || "Net 30 Days", 450, yT + 26);
    };

    const dibujarHeaderYMarco = (yInicio) => {
        doc.setFillColor(verdeClaro[0], verdeClaro[1], verdeClaro[2]);
        doc.rect(margenIzquierdo, yInicio, 530, 15, 'F'); // Fondo verde del header
        doc.rect(margenIzquierdo, yInicio, 530, yPiePagina - yInicio); // Marco total de la tabla
        
        // Líneas verticales del formato
        doc.line(110, yInicio, 110, yPiePagina);
        doc.line(210, yInicio, 210, yPiePagina);
        doc.line(420, yInicio, 420, yPiePagina);
        doc.line(500, yInicio, 500, yPiePagina);

        doc.setFont("helvetica", "bold").setTextColor(0);
        doc.text("Quantity", 55, yInicio + 11).text("Item", 150, yInicio + 11).text("Description", 280, yInicio + 11).text("Unit Cost", 435, yInicio + 11).text("Amount", 515, yInicio + 11);
    };

    // --- PROCESO DE DIBUJO ---
    let nPagina = 1;
    dibujarEncabezadoPrincipal(nPagina);
    dibujarBloquesInformacion();
    dibujarHeaderYMarco(yInicioTablaNormal);
    
    let yActual = yInicioTablaNormal + 25;

    items.forEach((obj, index) => {
        const lineasDesc = doc.splitTextToSize(obj.desc, 200);
        const lineasItem = doc.splitTextToSize(obj.item, 90);
        const altoFila = Math.max(doc.getTextDimensions(lineasDesc).h, doc.getTextDimensions(lineasItem).h) + 12;

        if (yActual + altoFila > limiteSalto) {
            doc.addPage();
            nPagina++;
            dibujarEncabezadoPrincipal(nPagina);
            dibujarHeaderYMarco(yInicioTablaSiguientes);
            yActual = yInicioTablaSiguientes + 25;
        }

        doc.setFont("helvetica", "normal").setFontSize(9);
        doc.text(obj.qty.toString(), 80, yActual, { align: "right" });
        doc.text(lineasItem, 115, yActual);
        doc.text(lineasDesc, 215, yActual);
        doc.text(parseFloat(obj.cost).toLocaleString('en-US', { minimumFractionDigits: 2 }), 485, yActual, { align: "right" });
        doc.text(parseFloat(obj.amount).toLocaleString('en-US', { minimumFractionDigits: 2 }), 560, yActual, { align: "right" });

        yActual += altoFila;
    });

    // --- TOTAL (Siempre al final de la tabla en la última página) ---
    doc.setFillColor(255, 255, 255);
    doc.rect(420, yPiePagina, 150, 20, 'FD');
    doc.setFont("helvetica", "bold").setFontSize(10).text("TOTAL", 430, yPiePagina + 14);
    doc.text(totalTxt, 560, yPiePagina + 14, { align: "right" });

    // --- FIRMA ---
    doc.setFontSize(9).setFont("helvetica", "normal").text("Authorized Signature", margenIzquierdo, 770);
    doc.line(130, 770, 300, 770);

    //doc.save(`Orden_Compra_${info.oc}.pdf`);

    return doc.output('blob');
}