import React, { Component } from 'react';
import { Navigation } from './Navigation';
import { SearchBar } from './SearchBar';
import { Services } from './Services';
import { SLAestimation } from './SLAestimation';

export class MainPanel extends Component {
    static displayName = MainPanel.name;

    constructor(props) {
        super(props);
        this.state = { serviceCategories: [], selectedServices: [], selectedCategory: "", slaEstimation: [], slaTotal: 0, filter: false, loading: true };
        this.selectCategory = this.selectCategory.bind(this);
        this.selectService = this.selectService.bind(this);
        this.searchTextEnter = this.searchTextEnter.bind(this);
        this.clearSearch = this.clearSearch.bind(this);
        this.deleteEstimationEntry = this.deleteEstimationEntry.bind(this);
        this.deleteAll = this.deleteAll.bind(this);
    }

    selectCategory(selectedCategory) {
        this.setState({
            selectedServices: selectedCategory.services,
            selectedCategory: selectedCategory.categoryName
        });
    }

    clearSearch(evt) {
        evt.currentTarget.parentElement.children[0].value = "";

        let displayServices = this.state.allservices.filter(o => o.categoryName === this.state.selectedCategory);

        this.setState({
            selectedServices: displayServices,
            filter: false
        });
    }

    searchTextEnter(textValue) {
        let displayServices = [];
        let filter = false;

        if (textValue.length > 0) {
            displayServices = this.state.allservices.filter(o => o.name.toLowerCase().includes(textValue.toLowerCase()));
            filter = true;
        }
        else {
            displayServices = this.state.allservices.filter(o => o.categoryName === this.state.selectedCategory);
        }

        this.setState({
            selectedServices: displayServices,
            filter: filter
        });
    }

    calculateSla(slaEstimation) {
        if (slaEstimation.length == 1)
            return slaEstimation[0].key.sla;

        let total = 1;
        let services = slaEstimation.map(x => x.key);

        for (var i = 0; i < services.length; i++) {
            total = total * services[i].sla / 100;
        }

        return total * 100;
    }

    calculateDownTime(sla) {
        if (sla == 0)
            return 0;

        return Math.round((44640 * (1 - (sla / 100)) + Number.EPSILON) * 100) / 100;
    }

    selectService(selectedService) {

        const service = this.state.selectedServices.find(o => o.name === selectedService);
        const slaEstimation = [...this.state.slaEstimation];

        slaEstimation.push({ id: this.state.slaEstimation.length, key: service });

        const slaTotal = this.calculateSla(slaEstimation);
        const downTime = this.calculateDownTime(slaTotal)

        this.setState({
            selectedService: selectedService,
            slaEstimation: slaEstimation,
            slaTotal: slaTotal,
            downTime: downTime
        });
    }

    deleteEstimationEntry(evt) {
        const estimationId = evt.currentTarget.parentElement.parentElement.id;
        const slaEstimation = [...this.state.slaEstimation];
        const slaEstimationEntry = slaEstimation.find(e => e.id === Number(estimationId));

        const index = slaEstimation.indexOf(slaEstimationEntry);

        slaEstimation.splice(index, 1);
        this.setState({ slaEstimation: slaEstimation });
    }

    deleteAll() {
        console.log("clicked delete");
        this.setState({ slaEstimation: [] });
    }

    componentDidMount() {
        this.populateServiceCategoryData();
    }

    renderMainPanel() {
        return (
            <div className="main-panel">
                <div className="top-panel">
                    <div className="top-title">
                        <h1 className="top-title-inner">SLA Estimator</h1>
                        <p className="top-title-inner-sub">Estimate the oeverall service level agreement of your services</p>
                    </div>
                    <div className="search-container">
                        <SearchBar onTextSearchEnter={this.searchTextEnter} onClearSearch={this.clearSearch} />
                    </div>
                    <div className="layout-parent-div">
                        <div className={!this.state.filter ? "layout-div-left" : "div-hide"}>
                            <Navigation visible={!this.state.filter} dataSource={this.state.serviceCategories} selectedCategory={this.state.selectedCategory} onSelectCategory={this.selectCategory} />
                        </div>
                        <div className={this.state.filter ? "layout-div-center" : "layout-div-right"}>
                            <Services dataSource={this.state.selectedServices} onSelectService={this.selectService} />
                        </div>
                    </div>
                </div>
                <div className="sla-estimation-panel">
                    <SLAestimation dataSource={this.state.slaEstimation} onDeleteEstimation={this.deleteEstimationEntry}
                        onDeleteAll={this.deleteAll} slaTotal={this.state.slaTotal} downTime={this.state.downTime} />
                </div>
            </div>
        );
    }

    render() {
        let contents = this.renderMainPanel();

        return (
            <div>
                {contents}
            </div>
        );
    }

    async populateServiceCategoryData() {
        const response = await fetch('servicecategory');
        const data = await response.json();

        const allservices = data.map(x => x.services).reduce(
            (x, y) => x.concat(y));

        this.setState({ serviceCategories: data, allservices, selectedServices: data[0].services, selectedCategory: data[0].categoryName, loading: false });
    }
}
