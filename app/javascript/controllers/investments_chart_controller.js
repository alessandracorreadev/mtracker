import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  connect() {
    const canvas = this.element.querySelector("#investments-chart")
    if (!canvas) return

    const raw = this.element.dataset.chartData
    const data = raw ? JSON.parse(raw) : []

    if (data.length === 0) return

    const labels = data.map((d) => d.name)
    const values = data.map((d) => Number(d.total))
    const colorsRaw = this.element.dataset.chartColors
    const colors = colorsRaw ? JSON.parse(colorsRaw) : ["#05b355", "#0d1b2a"]

    const percentageLabelsPlugin = {
      id: "percentageLabels",
      afterDatasetsDraw(chart, args, options) {
        const { ctx } = chart
        ctx.save()

        chart.data.datasets.forEach((dataset, i) => {
          const meta = chart.getDatasetMeta(i)
          let total = 0
          dataset.data.forEach(val => total += Number(val))

          meta.data.forEach((element, index) => {
            const val = Number(dataset.data[index])
            if (val === 0) return

            const percentage = ((val / total) * 100).toFixed(0) + "%"
            
            if ((val / total) > 0.05) {
              const { x, y } = element.tooltipPosition()
              ctx.fillStyle = "#ffffff"
              ctx.font = "bold 12px sans-serif"
              ctx.textAlign = "center"
              ctx.textBaseline = "middle"
              ctx.fillText(percentage, x, y)
            }
          })
        })
        ctx.restore()
      }
    }

    this.chart = new Chart(canvas, {
      type: "doughnut",
      plugins: [percentageLabelsPlugin],
      data: {
        labels,
        datasets: [
          {
            data: values,
            backgroundColor: labels.map((_, i) => colors[i % colors.length]),
            borderWidth: 2,
            borderColor: "rgba(255,255,255,0.1)",
            hoverOffset: 4
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        cutout: "60%",
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "#212529",
            titleFont: { size: 14, weight: "bold" },
            bodyFont: { size: 13 },
            padding: 12,
            cornerRadius: 12,
            displayColors: true,
            borderColor: "rgba(255,255,255,0.1)",
            borderWidth: 1
          }
        },
      },
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
